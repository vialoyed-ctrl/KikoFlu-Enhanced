package com.meteor.kikoeruflutter

import android.content.Intent
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.ProxySelector
import java.net.URI

class MainActivity : AudioServiceActivity() {
    private var videoBrightness: Float? = null
    private var videoKeepAwake = false

    private var floatingLyricPlugin: FloatingLyricPlugin? = null
    private var audioHapticsBridge: AudioHapticsBridge? = null
    private var subtitleDirectoryPicker: SubtitleDirectoryPicker? = null
    private val screenAwakeChannelName = "com.meteor.kikoeruflutter/screen_awake"
    private val systemProxyChannelName = "com.meteor.kikoeruflutter/system_proxy"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册悬浮字幕插件
        floatingLyricPlugin = FloatingLyricPlugin.getInstance(this)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FloatingLyricPlugin.CHANNEL
        )
        floatingLyricPlugin?.attachChannel(channel)
        channel.setMethodCallHandler(floatingLyricPlugin)
        audioHapticsBridge = AudioHapticsBridge(
            context = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger
        )
        subtitleDirectoryPicker = SubtitleDirectoryPicker(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.meteor.kikoeruflutter/video_display").setMethodCallHandler { call, result ->
            when (call.method) {
                "beginFullscreen" -> {
                    if (videoBrightness == null) {
                        videoBrightness = window.attributes.screenBrightness
                        videoKeepAwake = (window.attributes.flags and WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0
                    }
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    val current = window.attributes.screenBrightness
                    val fallback = android.provider.Settings.System.getInt(contentResolver,
                        android.provider.Settings.System.SCREEN_BRIGHTNESS, 128) / 255.0
                    result.success(if (current >= 0) current.toDouble() else fallback)
                }
                "setBrightness" -> {
                    val attributes = window.attributes
                    attributes.screenBrightness = (call.argument<Number>("value")?.toFloat() ?: 0.5f).coerceIn(0.01f, 1f)
                    window.attributes = attributes
                    result.success(null)
                }
                "endFullscreen" -> {
                    restoreVideoDisplay()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemProxyChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemProxy" -> result.success(getSystemProxy())
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            screenAwakeChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepScreenOn" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    runOnUiThread {
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun restoreVideoDisplay() {
        videoBrightness?.let {
            val attributes = window.attributes
            attributes.screenBrightness = it
            window.attributes = attributes
            if (!videoKeepAwake) window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            videoBrightness = null
        }
    }

    private fun getSystemProxy(): String? {
        val proxySelector = ProxySelector.getDefault() ?: return null
        val urls = listOf(
            URI("https://api.asmr-200.com/"),
            URI("http://api.asmr-200.com/")
        )

        for (url in urls) {
            try {
                val proxy = proxySelector.select(url).firstOrNull {
                    it.type() == Proxy.Type.HTTP
                } ?: continue
                val address = proxy.address() as? InetSocketAddress ?: continue
                return "${address.hostString}:${address.port}"
            } catch (_: Exception) {
                // Try the next URL, then fall back to the legacy JVM properties.
            }
        }

        val host = System.getProperty("http.proxyHost")
        val port = System.getProperty("http.proxyPort")
        return if (!host.isNullOrBlank() && !port.isNullOrBlank()) {
            "$host:$port"
        } else {
            null
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (subtitleDirectoryPicker?.handleActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        restoreVideoDisplay()
        // 不在 Activity 销毁时清理悬浮窗，以便在后台（如侧滑返回桌面）时保持显示
        // floatingLyricPlugin?.cleanup()
        audioHapticsBridge?.dispose()
        audioHapticsBridge = null
        subtitleDirectoryPicker?.dispose()
        subtitleDirectoryPicker = null
        super.onDestroy()
    }
}
