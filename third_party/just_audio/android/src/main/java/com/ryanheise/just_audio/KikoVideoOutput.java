package com.ryanheise.just_audio;

import androidx.media3.common.Player;
import androidx.media3.common.VideoSize;
import androidx.media3.common.text.Cue;
import androidx.media3.common.text.CueGroup;
import androidx.media3.exoplayer.ExoPlayer;
import io.flutter.view.TextureRegistry;
import java.util.HashMap;
import java.util.Map;

/** A visual output for the existing player, not a second playback engine. */
final class KikoVideoOutput implements Player.Listener {
    private final TextureRegistry textures;
    private TextureRegistry.SurfaceProducer producer;
    private ExoPlayer owner;
    private VideoSize size = VideoSize.UNKNOWN;
    private String subtitles = "";
    private boolean firstFrame;

    KikoVideoOutput(TextureRegistry textures) { this.textures = textures; }

    Map<String, Object> status(ExoPlayer player) {
        if (producer == null) {
            owner = player;
            producer = textures.createSurfaceProducer();
            producer.setSize(Math.max(1, size.width), Math.max(1, size.height));
            producer.setCallback(new TextureRegistry.SurfaceProducer.Callback() {
                @Override public void onSurfaceAvailable() {
                    if (owner != null && producer != null) {
                        firstFrame = false;
                        owner.setVideoSurface(producer.getSurface());
                    }
                }
                @Override public void onSurfaceCleanup() {
                    if (owner != null) owner.clearVideoSurface();
                    firstFrame = false;
                }
            });
            player.setVideoSurface(producer.getSurface());
            player.setTrackSelectionParameters(player.getTrackSelectionParameters()
                .buildUpon().setSelectUndeterminedTextLanguage(true).build());
        }
        Map<String, Object> result = new HashMap<>();
        result.put("textureId", producer.id());
        result.put("width", size.width);
        result.put("height", size.height);
        result.put("pixelRatio", size.pixelWidthHeightRatio);
        result.put("firstFrame", firstFrame);
        result.put("subtitles", subtitles);
        return result;
    }

    @Override public void onVideoSizeChanged(VideoSize value) {
        size = value;
        if (producer != null) producer.setSize(Math.max(1, size.width), Math.max(1, size.height));
    }
    @Override public void onRenderedFirstFrame() { firstFrame = true; }
    @Override public void onCues(CueGroup group) {
        StringBuilder text = new StringBuilder();
        for (Cue cue : group.cues) {
            if (cue.text != null) {
                if (text.length() > 0) text.append('\n');
                text.append(cue.text);
            }
        }
        subtitles = text.toString();
    }
    void reset() { size = VideoSize.UNKNOWN; subtitles = ""; firstFrame = false; }
    void detach(ExoPlayer player) {
        player.clearVideoSurface();
        owner = null;
        if (producer != null) {
            producer.setCallback(null);
            producer.release();
            producer = null;
        }
        reset();
    }
}
