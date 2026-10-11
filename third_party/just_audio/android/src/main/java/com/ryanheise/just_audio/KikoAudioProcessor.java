package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.common.audio.BaseAudioProcessor;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** PCM stays on the playback thread. Settings are immutable block-boundary snapshots. */
final class KikoAudioProcessor extends BaseAudioProcessor {
    static { System.loadLibrary("kikodsp"); }
    private volatile double[] pending = new double[43];
    private double[] applied;
    private long handle;
    private volatile int rate, channels;
    private volatile long frames;
    private volatile boolean supported;
    KikoAudioProcessor() { pending[2] = 1; }
    boolean enabled() { return pending[0] != 0; }
    void setConfig(Map<?, ?> config) {
        double[] v = new double[43];
        v[0] = Boolean.TRUE.equals(config.get("enabled")) ? 1 : 0;
        v[1] = number(config.get("preamp"), 0); v[2] = number(config.get("width"), 1);
        Object raw = config.get("bands");
        List<?> bands = raw instanceof List ? (List<?>) raw : java.util.Collections.emptyList();
        for (int i=0;i<10;i++) {
            Map<?,?> b = i<bands.size() && bands.get(i) instanceof Map ? (Map<?,?>)bands.get(i) : java.util.Collections.emptyMap();
            v[3+4*i]=number(b.get("type"),0);v[4+4*i]=number(b.get("frequency"),1000);v[5+4*i]=number(b.get("gain"),0);v[6+4*i]=number(b.get("q"),1.5);
        }
        pending = v;
    }
    private static double number(Object v,double fallback) {double d=v instanceof Number?((Number)v).doubleValue():fallback;return Double.isFinite(d)?d:fallback;}
    Map<String,Object> status() {Map<String,Object> s=new HashMap<>();s.put("enabled",enabled());s.put("supported",supported);s.put("sampleRate",rate);s.put("channels",channels);s.put("processedFrames",frames);return s;}
    @Override protected AudioFormat onConfigure(AudioFormat format) {
        return format.encoding==C.ENCODING_PCM_16BIT && (format.channelCount==1||format.channelCount==2) ? format : AudioFormat.NOT_SET;
    }
    @Override public void queueInput(ByteBuffer input) {
        int bytes=input.remaining();if(bytes==0)return;
        ByteBuffer output=replaceOutputBuffer(bytes);output.put(input);output.flip();
        double[] config=pending;
        if(handle==0)handle=nativeCreate(rate,channels);
        if(config!=applied){nativeConfigure(handle,config);applied=config;}
        nativeProcess(handle,output,bytes/(2*channels));
        if(config[0]!=0)frames+=bytes/(2*channels);
    }
    @Override protected void onFlush() {if(handle!=0){nativeDestroy(handle);handle=0;}applied=null;frames=0;rate=inputAudioFormat.sampleRate;channels=inputAudioFormat.channelCount;supported=inputAudioFormat.encoding==C.ENCODING_PCM_16BIT&&(channels==1||channels==2);}
    @Override protected void onReset() {release();rate=0;channels=0;supported=false;}
    void release() {if(handle!=0){nativeDestroy(handle);handle=0;}applied=null;}
    private static native long nativeCreate(int rate,int channels);
    private static native void nativeConfigure(long handle,double[] values);
    private static native void nativeProcess(long handle,ByteBuffer buffer,int frames);
    private static native void nativeDestroy(long handle);
}
