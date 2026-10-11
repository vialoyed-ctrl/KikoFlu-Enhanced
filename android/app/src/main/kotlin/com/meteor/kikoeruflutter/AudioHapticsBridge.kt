package com.meteor.kikoeruflutter

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.concurrent.thread
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

class AudioHapticsBridge(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = appContext.getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    @Volatile
    private var analysisGeneration = 0

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "analyze" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("bad_args", "Missing audio path", null)
                    return
                }
                val frameMs = call.argument<Int>("frameMs") ?: DEFAULT_FRAME_MS
                val maxDurationMs =
                    call.argument<Int>("maxDurationMs") ?: DEFAULT_MAX_DURATION_MS
                thread(name = "audio-haptics-analyze", isDaemon = true) {
                    try {
                        val analysis = analyzeFile(
                            path = path,
                            frameMs = frameMs,
                            maxDurationMs = maxDurationMs,
                        )
                        mainHandler.post { result.success(analysis) }
                    } catch (error: Throwable) {
                        mainHandler.post {
                            result.error("analysis_failed", error.message, null)
                        }
                    }
                }
            }

            "startFileStreamAnalysis", "startGrowingFileAnalysis" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("bad_args", "Missing audio path", null)
                    return
                }
                val finalPath = call.argument<String>("finalPath")
                val frameMs = call.argument<Int>("frameMs") ?: DEFAULT_FRAME_MS
                val maxDurationMs =
                    call.argument<Int>("maxDurationMs") ?: DEFAULT_MAX_DURATION_MS
                val startPositionMs = call.argument<Int>("startPositionMs") ?: 0
                val analysisToken = call.argument<Int>("analysisToken") ?: 0
                val growingFile = call.method == "startGrowingFileAnalysis"
                val generation = nextGeneration()
                thread(name = "audio-haptics-stream", isDaemon = true) {
                    streamAnalyzeFile(
                        path = path,
                        finalPath = finalPath,
                        frameMs = frameMs,
                        maxDurationMs = maxDurationMs,
                        startPositionMs = startPositionMs,
                        generation = generation,
                        analysisToken = analysisToken,
                        growingFile = growingFile,
                    )
                }
                result.success(null)
            }

            "pulse" -> {
                val intensity = call.argument<Double>("intensity") ?: 0.5
                val durationMs = call.argument<Int>("durationMs") ?: 40
                pulse(intensity, durationMs)
                result.success(null)
            }

            "silence" -> {
                vibrator?.cancel()
                result.success(null)
            }

            "stop" -> {
                nextGeneration()
                vibrator?.cancel()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    fun dispose() {
        nextGeneration()
        vibrator?.cancel()
        channel.setMethodCallHandler(null)
    }

    private fun streamAnalyzeFile(
        path: String,
        finalPath: String?,
        frameMs: Int,
        maxDurationMs: Int,
        startPositionMs: Int,
        generation: Int,
        analysisToken: Int,
        growingFile: Boolean,
    ) {
        val resolvedFrameMs = frameMs.coerceIn(20, 200)
        val chunkFrames = if (growingFile) 24 else 240
        var nextFrame = max(0, startPositionMs / resolvedFrameMs)
        var retryCount = 0

        while (generation == analysisGeneration) {
            try {
                val readablePath = readableAnalysisPath(path, finalPath)
                val analysis = analyzeFile(
                    path = readablePath,
                    frameMs = resolvedFrameMs,
                    maxDurationMs = maxDurationMs,
                    startFrame = nextFrame,
                    maxEnergyFrames = chunkFrames,
                )
                if (generation != analysisGeneration) return

                @Suppress("UNCHECKED_CAST")
                val energies = analysis["energies"] as? List<Double> ?: emptyList()
                val chunkStartFrame = analysis["startFrame"] as? Int ?: nextFrame

                if (energies.isNotEmpty()) {
                    sendAnalysisChunk(
                        analysisToken = analysisToken,
                        frameMs = resolvedFrameMs,
                        startFrame = chunkStartFrame,
                        energies = energies,
                    )
                    nextFrame = chunkStartFrame + energies.size
                    retryCount = 0
                }

                val finalReady = !finalPath.isNullOrBlank() && File(finalPath).exists()
                if (energies.isEmpty() && (!growingFile || finalReady)) {
                    sendAnalysisFinished(analysisToken)
                    return
                }

                if (nextFrame * resolvedFrameMs >= maxDurationMs) {
                    sendAnalysisFinished(analysisToken)
                    return
                }

                val sleepMs = if (energies.isEmpty()) {
                    if (growingFile) 750L else 20L
                } else {
                    if (growingFile) 120L else 20L
                }
                Thread.sleep(sleepMs)
            } catch (error: Throwable) {
                if (generation != analysisGeneration) return
                val finalReady = !finalPath.isNullOrBlank() && File(finalPath).exists()
                if (!growingFile || (finalReady && retryCount >= 24) || retryCount >= 240) {
                    sendAnalysisFailed(
                        analysisToken,
                        error.message ?: error.javaClass.simpleName,
                    )
                    return
                }
                retryCount += 1
                Thread.sleep(500L)
            }
        }
    }

    private fun analyzeFile(
        path: String,
        frameMs: Int,
        maxDurationMs: Int,
        startFrame: Int = 0,
        maxEnergyFrames: Int? = null,
    ): Map<String, Any> {
        val resolvedFrameMs = frameMs.coerceIn(20, 200)
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null

        try {
            extractor.setDataSource(path)
            val trackIndex = selectAudioTrack(extractor)
            if (trackIndex < 0) {
                return emptyAnalysis(resolvedFrameMs, startFrame)
            }

            val format = extractor.getTrackFormat(trackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME)
                ?: return emptyAnalysis(resolvedFrameMs, startFrame)
            val durationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) {
                format.getLong(MediaFormat.KEY_DURATION)
            } else {
                0L
            }
            val durationMs = (durationUs / 1000L).toInt()
            val startTimeUs = max(0, startFrame).toLong() * resolvedFrameMs * 1000L
            val maxTimeUs = min(
                if (durationUs > 0L) durationUs else Long.MAX_VALUE,
                maxDurationMs.toLong() * 1000L,
            )
            if (startTimeUs >= maxTimeUs) {
                return mapOf(
                    "frameMs" to resolvedFrameMs,
                    "startFrame" to max(0, startFrame),
                    "durationMs" to durationMs,
                    "energies" to emptyList<Double>(),
                )
            }

            extractor.selectTrack(trackIndex)
            extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(format, null, null, 0)
            decoder.start()

            val buckets = mutableListOf<_RmsBucket>()
            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var outputFormat = decoder.outputFormat

            while (!outputDone) {
                if (!inputDone) {
                    val inputIndex = decoder.dequeueInputBuffer(DEQUEUE_TIMEOUT_US)
                    if (inputIndex >= 0) {
                        val inputBuffer = decoder.getInputBuffer(inputIndex)
                        if (inputBuffer == null ||
                            extractor.sampleTrackIndex != trackIndex ||
                            extractor.sampleTime < 0 ||
                            extractor.sampleTime >= maxTimeUs
                        ) {
                            decoder.queueInputBuffer(
                                inputIndex,
                                0,
                                0,
                                0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            inputBuffer.clear()
                            val sampleSize = extractor.readSampleData(inputBuffer, 0)
                            if (sampleSize < 0) {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                                )
                                inputDone = true
                            } else {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    sampleSize,
                                    extractor.sampleTime,
                                    extractor.sampleFlags,
                                )
                                extractor.advance()
                            }
                        }
                    }
                }

                when (val outputIndex = decoder.dequeueOutputBuffer(info, DEQUEUE_TIMEOUT_US)) {
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        outputFormat = decoder.outputFormat
                    }

                    MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        if (inputDone) {
                            break
                        }
                    }

                    else -> {
                        if (outputIndex >= 0) {
                            val outputBuffer = decoder.getOutputBuffer(outputIndex)
                            if (outputBuffer != null && info.size > 0) {
                                val shouldStop = consumePcmBuffer(
                                    buffer = outputBuffer,
                                    info = info,
                                    format = outputFormat,
                                    resolvedFrameMs = resolvedFrameMs,
                                    startFrame = startFrame,
                                    maxEnergyFrames = maxEnergyFrames,
                                    buckets = buckets,
                                )
                                if (shouldStop) {
                                    outputDone = true
                                }
                            }
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                outputDone = true
                            }
                            decoder.releaseOutputBuffer(outputIndex, false)
                        }
                    }
                }
            }

            return mapOf(
                "frameMs" to resolvedFrameMs,
                "startFrame" to max(0, startFrame),
                "durationMs" to durationMs,
                "energies" to buckets.map { it.value() },
            )
        } finally {
            try {
                decoder?.stop()
            } catch (_: Throwable) {
            }
            decoder?.release()
            extractor.release()
        }
    }

    private fun consumePcmBuffer(
        buffer: ByteBuffer,
        info: MediaCodec.BufferInfo,
        format: MediaFormat,
        resolvedFrameMs: Int,
        startFrame: Int,
        maxEnergyFrames: Int?,
        buckets: MutableList<_RmsBucket>,
    ): Boolean {
        val sampleRate = if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
            format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        } else {
            44100
        }.coerceAtLeast(1)
        val channels = if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
            format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        } else {
            1
        }.coerceAtLeast(1)
        val pcmEncoding = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
            format.containsKey(MediaFormat.KEY_PCM_ENCODING)
        ) {
            format.getInteger(MediaFormat.KEY_PCM_ENCODING)
        } else {
            AudioFormat.ENCODING_PCM_16BIT
        }
        val bytesPerSample = when (pcmEncoding) {
            AudioFormat.ENCODING_PCM_FLOAT -> 4
            AudioFormat.ENCODING_PCM_8BIT -> 1
            else -> 2
        }

        val data = buffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
        data.position(info.offset)
        data.limit(info.offset + info.size)

        var sampleIndex = 0
        while (data.remaining() >= bytesPerSample) {
            val sample = when (pcmEncoding) {
                AudioFormat.ENCODING_PCM_FLOAT -> data.float.coerceIn(-1f, 1f).toDouble()
                AudioFormat.ENCODING_PCM_8BIT ->
                    ((data.get().toInt() and 0xff) - 128) / 128.0
                else -> data.short / 32768.0
            }
            val pcmFrameIndex = sampleIndex / channels
            val sampleTimeUs =
                info.presentationTimeUs + pcmFrameIndex * 1_000_000L / sampleRate
            val energyFrame = (sampleTimeUs / 1000L / resolvedFrameMs).toInt()
            if (energyFrame >= startFrame) {
                if (maxEnergyFrames != null && energyFrame >= startFrame + maxEnergyFrames) {
                    return true
                }
                val bucketIndex = energyFrame - startFrame
                while (buckets.size <= bucketIndex) {
                    buckets.add(_RmsBucket())
                }
                buckets[bucketIndex].add(sample)
            }
            sampleIndex += 1
        }

        return false
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int {
        for (index in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(index)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) return index
        }
        return -1
    }

    private fun emptyAnalysis(frameMs: Int, startFrame: Int): Map<String, Any> {
        return mapOf(
            "frameMs" to frameMs,
            "startFrame" to max(0, startFrame),
            "durationMs" to 0,
            "energies" to emptyList<Double>(),
        )
    }

    private fun pulse(intensity: Double, durationMs: Int) {
        val resolvedVibrator = vibrator ?: return
        val clampedIntensity = intensity.coerceIn(0.1, 1.0)
        val clampedDuration = durationMs.coerceIn(10, 120).toLong()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amplitude = (clampedIntensity * 255).toInt().coerceIn(1, 255)
            resolvedVibrator.vibrate(
                VibrationEffect.createOneShot(clampedDuration, amplitude)
            )
        } else {
            @Suppress("DEPRECATION")
            resolvedVibrator.vibrate(clampedDuration)
        }
    }

    private fun readableAnalysisPath(path: String, finalPath: String?): String {
        if (File(path).exists()) return path
        if (!finalPath.isNullOrBlank() && File(finalPath).exists()) return finalPath
        return path
    }

    private fun sendAnalysisChunk(
        analysisToken: Int,
        frameMs: Int,
        startFrame: Int,
        energies: List<Double>,
    ) {
        mainHandler.post {
            channel.invokeMethod(
                "analysisChunk",
                mapOf(
                    "analysisToken" to analysisToken,
                    "frameMs" to frameMs,
                    "startFrame" to startFrame,
                    "energies" to energies,
                ),
            )
        }
    }

    private fun sendAnalysisFinished(analysisToken: Int) {
        mainHandler.post {
            channel.invokeMethod("analysisFinished", mapOf("analysisToken" to analysisToken))
        }
    }

    private fun sendAnalysisFailed(analysisToken: Int, message: String) {
        mainHandler.post {
            channel.invokeMethod(
                "analysisFailed",
                mapOf(
                    "analysisToken" to analysisToken,
                    "message" to message,
                ),
            )
        }
    }

    @Synchronized
    private fun nextGeneration(): Int {
        analysisGeneration += 1
        return analysisGeneration
    }

    private class _RmsBucket {
        private var sumSquares = 0.0
        private var count = 0

        fun add(sample: Double) {
            sumSquares += sample * sample
            count += 1
        }

        fun value(): Double {
            if (count == 0) return 0.0
            return (sqrt(sumSquares / count) * 2.8).coerceIn(0.0, 1.0)
        }
    }

    private companion object {
        const val CHANNEL_NAME = "com.meteor.kikoeruflutter/audio_haptics"
        const val DEFAULT_FRAME_MS = 50
        const val DEFAULT_MAX_DURATION_MS = 3 * 60 * 60 * 1000
        const val DEQUEUE_TIMEOUT_US = 10_000L
    }
}
