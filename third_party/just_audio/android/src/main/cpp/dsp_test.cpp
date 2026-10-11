#include "audio_dsp.h"
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>
using namespace kiko;
void check(bool ok, const char* message) { if (!ok) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(1); } }
int main() {
  Engine engine;
  engine.prepare(48000, 2);
  Config config;
  std::vector<float> samples{0.1f,-0.2f,0.7f,-0.8f};
  auto original = samples;
  engine.process(samples.data(),2);
  check(samples == original,"disabled output must be identical");
  config.enabled=true; config.width=0;
  engine.configure(config);
  samples.assign(48000*2,0.0f);
  for(int i=0;i<48000;i++) { samples[2*i]=0.1f; samples[2*i+1]=-0.1f; }
  engine.process(samples.data(),48000);
  check(std::abs(samples.back())<0.00001,"width zero cancels pure side");
  engine.reset(); config.width=1; config.bands[0]={0,1000,6,1.5};
  engine.configure(config);
  for(int i=0;i<48000;i++) samples[2*i]=samples[2*i+1]=0.05f*std::sin(2*3.141592653589793*1000*i/48000);
  engine.process(samples.data(),48000);
  double energy=0; for(int i=24000;i<48000;i++) energy+=samples[2*i]*samples[2*i];
  check(std::abs(std::sqrt(energy/24000)/(0.05/std::sqrt(2))-1.995262)<0.01,"+6 dB at peak center");
  engine.reset(); config.preamp=12; config.width=2;
  engine.configure(config);
  for(int i=0;i<48000;i++) {samples[2*i]=i%2?1.f:-1.f; samples[2*i+1]=samples[2*i]*0.5f;}
  engine.process(samples.data(),48000);
  for(float sample:samples) check(std::isfinite(sample)&&std::abs(sample)<=0.891251f,"limiter ceiling -1 dBFS");
  config.enabled=false;engine.configure(config);samples.assign(48000*2,0);engine.process(samples.data(),48000);samples=original;engine.process(samples.data(),2);
  check(samples==original,"turning off restores exact samples");
  engine.reset(); config.enabled=true; config.preamp=NAN;config.width=NAN;config.bands[0]={0,NAN,NAN,0};engine.configure(config);
  samples.assign(1000,0);engine.process(samples.data(),500);
  for(float sample:samples)check(std::isfinite(sample),"invalid values cannot contaminate output");
  Engine transition;transition.prepare(48000,2);Config fading;fading.enabled=true;fading.preamp=6;transition.configure(fading);
  samples.assign(48000*2,.1f);transition.process(samples.data(),48000);const float before=samples.back();
  fading.enabled=false;transition.configure(fading);float after[2]={.1f,.1f};transition.process(after,1);
  check(std::abs(after[0]-before)<.01,"disable must fade without an abrupt level jump");
  const float fadingSample=after[0];fading.enabled=true;transition.configure(fading);after[0]=after[1]=.1f;transition.process(after,1);
  check(std::abs(after[0]-fadingSample)<.01,"rapid off/on must preserve transition state");
  fading.enabled=false;transition.configure(fading);
  samples.assign(48000*2,.1f);transition.process(samples.data(),48000);
  check(samples.back()==.1f,"fade completes into exact bypass");
  std::puts("PASS: bypass, stereo, EQ response, limiter, reset, invalid input, switch fade");
}
