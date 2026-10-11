# KikoFlu DSP patch

Based on upstream just_audio 0.9.44, tag commit e9f1e6eb68d70435e997f043f00623fd9a81bff3. Upstream licensing remains unchanged.

Android adds a per-player KikoAudioProcessor after Media3's speed processor, a JNI C++ EQ/M/S/linked peak limiter, and configuration/status calls. Processing is PCM16 mono/stereo. Float output is disabled. Enabled DSP explicitly disables offload. Disabled DSP copies PCM bytes unchanged and retains original offload preferences.

Limiter: zero lookahead, immediate linked attack, 80 ms release, -1 dBFS sample ceiling. This avoids buffering and added subtitle latency but is not a true-peak/lookahead limiter; heavy limiting may color transients. Parameters and dry/wet transitions smooth with a 20 ms time constant. Disable settles into exact byte bypass (under 300 ms). Total preamp supports +/-24 dB to combine the editable +/-12 dB preamp with the original global +/-12 dB gain.

Enabled DSP refuses encoded passthrough in a ForwardingAudioSink. Switching on from an encoded output re-prepares the media source with resetPosition=false, retaining position and play intent. PCM switches do not re-prepare. Unsupported multichannel PCM bypasses DSP and is reported by status.

No JamesDSP code is used. Filter equations are independently implemented from the W3C Audio EQ Cookbook. Native tests build dsp_test.cpp using a host C++17 compiler.
