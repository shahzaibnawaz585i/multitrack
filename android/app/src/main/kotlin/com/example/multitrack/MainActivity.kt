package com.example.multitrack

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.multitrack/phone"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDialer" -> {
                    try {
                        val number = call.argument<String>("number").orEmpty().trim()
                        val uri = if (number.isEmpty()) {
                            Uri.fromParts("tel", "", null)
                        } else {
                            Uri.fromParts("tel", number, null)
                        }

                        val dialIntent = Intent(Intent.ACTION_DIAL).apply {
                            data = uri
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(dialIntent)
                        result.success(true)
                    } catch (error: Exception) {
                        try {
                            val fallback = Intent(Intent.ACTION_VIEW).apply {
                                data = Uri.parse("tel:")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallback)
                            result.success(true)
                        } catch (fallbackError: Exception) {
                            result.error(
                                "DIALER_ERROR",
                                fallbackError.message ?: error.message,
                                null,
                            )
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
