#include <jni.h>
#include "audio_dsp.h"
extern "C" {
JNIEXPORT jlong JNICALL Java_com_ryanheise_just_1audio_KikoAudioProcessor_nativeCreate(JNIEnv*,jclass,jint rate,jint channels) {auto* e=new kiko::Engine();e->prepare(rate,channels);return reinterpret_cast<jlong>(e);}
JNIEXPORT void JNICALL Java_com_ryanheise_just_1audio_KikoAudioProcessor_nativeConfigure(JNIEnv* env,jclass,jlong handle,jdoubleArray values) {
  if(!handle||env->GetArrayLength(values)!=43)return;
  double v[43];env->GetDoubleArrayRegion(values,0,43,v);kiko::Config c;c.enabled=v[0]!=0;c.preamp=v[1];c.width=v[2];
  for(int i=0;i<10;i++)c.bands[i]={static_cast<int>(v[3+4*i]),v[4+4*i],v[5+4*i],v[6+4*i]};
  reinterpret_cast<kiko::Engine*>(handle)->configure(c);
}
JNIEXPORT void JNICALL Java_com_ryanheise_just_1audio_KikoAudioProcessor_nativeProcess(JNIEnv* env,jclass,jlong handle,jobject buffer,jint frames) {if(handle)reinterpret_cast<kiko::Engine*>(handle)->processPcm(static_cast<std::int16_t*>(env->GetDirectBufferAddress(buffer)),frames);}
JNIEXPORT void JNICALL Java_com_ryanheise_just_1audio_KikoAudioProcessor_nativeReset(JNIEnv*,jclass,jlong handle) {if(handle)reinterpret_cast<kiko::Engine*>(handle)->reset();}
JNIEXPORT void JNICALL Java_com_ryanheise_just_1audio_KikoAudioProcessor_nativeDestroy(JNIEnv*,jclass,jlong handle) {delete reinterpret_cast<kiko::Engine*>(handle);}
}
