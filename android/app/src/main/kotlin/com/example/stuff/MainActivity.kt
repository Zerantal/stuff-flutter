package com.example.stuff // Change to your actual package name

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall

class MainActivity : FlutterActivity() {
    private val NATIVE_TAG = "MainActivityNative"
    private val LOG_CHANNEL = "com.example.stuff/log"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOG_CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "log") {
                val tag = call.argument<String>("tag") ?: "FlutterLog"
                val message = call.argument<String>("message") ?: ""
                val error = call.argument<String>("error")
                val stackTrace = call.argument<String>("stackTrace")

                var fullMessage = message
                if (error != null) {
                    fullMessage += "\nERROR: $error"
                }
                if (stackTrace != null) {
                    fullMessage += "\nSTACKTRACE: $stackTrace"
                }

                // Determine Android log level (optional, default to Log.d)
                when {
                    message.startsWith("SEVERE:") || message.startsWith("SHOUT:") || error != null -> Log.e(tag, fullMessage)
                    message.startsWith("WARNING:") -> Log.w(tag, fullMessage)
                    message.startsWith("INFO:") -> Log.i(tag, fullMessage)
                    else -> Log.d(tag, fullMessage) // Default for FINE, FINER, FINEST, CONFIG
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(NATIVE_TAG, "onCreate - START")
        super.onCreate(savedInstanceState)
        Log.d(NATIVE_TAG, "onCreate - END")
    }

    override fun onResume() {
        Log.d(NATIVE_TAG, "onResume - START")
        super.onResume()
        Log.d(NATIVE_TAG, "onResume - END")
    }

    override fun onPause() {
        Log.d(NATIVE_TAG, "onPause - START")
        super.onPause()
        Log.d(NATIVE_TAG, "onPause - END")
    }

    override fun onDestroy() {
        Log.d(NATIVE_TAG, "onDestroy - START")
        super.onDestroy()
        Log.d(NATIVE_TAG, "onDestroy - END")
    }
}
