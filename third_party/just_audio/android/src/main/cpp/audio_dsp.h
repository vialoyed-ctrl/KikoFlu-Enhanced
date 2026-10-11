#pragma once
#include <array>
#include <algorithm>
#include <cmath>
#include <cstdint>

namespace kiko {
constexpr double pi = 3.14159265358979323846;
inline double clean(double v,double fallback,double lo,double hi) { return std::isfinite(v)?std::clamp(v,lo,hi):fallback; }
struct Band { int type=0; double frequency=1000,gain=0,q=1.5; };
struct Config { bool enabled=false; double preamp=0,width=1; std::array<Band,10> bands{}; };
struct Coeff { double b0=1,b1=0,b2=0,a1=0,a2=0; };
inline Coeff coefficients(Band b,double rate) {
  const double f=clean(b.frequency,1000,20,std::min(20000.0,rate*0.45));
  const double gain=clean(b.gain,0,-12,12),q=clean(b.q,1.5,0.2,10);
  if(std::abs(gain)<1e-9)return {};
  const double A=std::pow(10,gain/40),w=2*pi*f/rate,c=std::cos(w),s=std::sin(w),alpha=s/(2*q);
  double b0,b1,b2,a0,a1,a2;
  if(b.type==1||b.type==2) {
    const double t=2*std::sqrt(A)*alpha;
    if(b.type==1) {
      b0=A*((A+1)-(A-1)*c+t);b1=2*A*((A-1)-(A+1)*c);b2=A*((A+1)-(A-1)*c-t);
      a0=(A+1)+(A-1)*c+t;a1=-2*((A-1)+(A+1)*c);a2=(A+1)+(A-1)*c-t;
    } else {
      b0=A*((A+1)+(A-1)*c+t);b1=-2*A*((A-1)+(A+1)*c);b2=A*((A+1)+(A-1)*c-t);
      a0=(A+1)-(A-1)*c+t;a1=2*((A-1)-(A+1)*c);a2=(A+1)-(A-1)*c-t;
    }
  } else {b0=1+alpha*A;b1=-2*c;b2=1-alpha*A;a0=1+alpha/A;a1=-2*c;a2=1-alpha/A;}
  return {b0/a0,b1/a0,b2/a0,a1/a0,a2/a0};
}
class Engine {
  double rate_=48000; int channels_=2;
  Config config_;
  std::array<Coeff,10> current_{},target_{};
  struct State { double z1=0,z2=0; };
  std::array<std::array<State,2>,10> states_{};
  double level_=1,width_=1,limiter_=1,wet_=0;
  double smooth_=0.001,release_=0.9997;
  void frame(float* x) {
    constexpr double ceiling=0.8912509381337456;
    const double levelTarget=std::pow(10,config_.preamp/20);
    level_+=smooth_*(levelTarget-level_);width_+=smooth_*(config_.width-width_);wet_+=smooth_*((config_.enabled?1.0:0.0)-wet_);
    double dry[2]={x[0],channels_==2?x[1]:0},y[2]={dry[0]*level_,dry[1]*level_};
    for(int i=0;i<10;i++) {
      auto& c=current_[i];const auto& t=target_[i];
      c.b0+=smooth_*(t.b0-c.b0);c.b1+=smooth_*(t.b1-c.b1);c.b2+=smooth_*(t.b2-c.b2);c.a1+=smooth_*(t.a1-c.a1);c.a2+=smooth_*(t.a2-c.a2);
      for(int ch=0;ch<channels_;ch++) {auto& st=states_[i][ch];const double out=c.b0*y[ch]+st.z1;st.z1=c.b1*y[ch]-c.a1*out+st.z2;st.z2=c.b2*y[ch]-c.a2*out;y[ch]=out;}
    }
    if(channels_==2) {const double mid=(y[0]+y[1])*0.5,side=(y[0]-y[1])*0.5*width_;y[0]=mid+side;y[1]=mid-side;}
    double peak=0;
    for(int ch=0;ch<channels_;ch++) {if(config_.enabled)y[ch]=dry[ch]+wet_*(y[ch]-dry[ch]);if(!std::isfinite(y[ch]))y[ch]=0;peak=std::max(peak,std::abs(y[ch]));}
    const double requested=peak>ceiling?ceiling/peak:1;
    limiter_=requested<limiter_?requested:std::min(requested,1-(1-limiter_)*release_);
    for(int ch=0;ch<channels_;ch++) {const double limited=std::clamp(y[ch]*limiter_,-ceiling,ceiling);x[ch]=static_cast<float>(config_.enabled?limited:dry[ch]+wet_*(limited-dry[ch]));}
  }
public:
  void prepare(int sampleRate,int channels) { rate_=std::max(8000,sampleRate);channels_=channels==1?1:2;smooth_=1-std::exp(-1/(0.02*rate_));release_=std::exp(-1/(0.08*rate_));reset();configure(config_); }
  void reset() {states_={};current_={};level_=1;width_=1;limiter_=1;wet_=0;}
  void configure(Config c) {
    c.preamp=clean(c.preamp,0,-24,24);c.width=clean(c.width,1,0,2);
    if(c.enabled && !config_.enabled && wet_==0)reset();config_=c;
    for(int i=0;i<10;i++)target_[i]=coefficients(c.bands[i],rate_);
  }
  void process(float* data,int frames) {for(int i=0;i<frames;i++){if(!config_.enabled && wet_<1e-6){wet_=0;return;}frame(data+i*channels_);}}
  void processPcm(std::int16_t* data,int frames) {
    for(int i=0;i<frames;i++) {if(!config_.enabled && wet_<1e-6){wet_=0;return;}float x[2]={data[i*channels_]/32768.f,channels_==2?data[i*channels_+1]/32768.f:0};frame(x);for(int ch=0;ch<channels_;ch++)data[i*channels_+ch]=static_cast<std::int16_t>(std::clamp(std::lround(x[ch]*32768),-32768L,32767L));}
  }
};
}
