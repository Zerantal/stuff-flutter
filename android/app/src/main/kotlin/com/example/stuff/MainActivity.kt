package com.example.stuff // TODO: Change to your actual package name

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val MEDIA_CHANNEL = "com.example.stuff/media"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImage") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val name = call.argument<String>("name") ?: "image.jpg"
                    val album = call.argument<String>("album") ?: "Stuff"

                    if (bytes == null) {
                        result.error("ARG", "Missing 'bytes'", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val ok = saveImageToGallery(bytes, name, album)
                        result.success(ok)
                    } catch (e: Exception) {
                        result.error("IO", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveImageToGallery(bytes: ByteArray, name: String, album: String): Boolean {
        val mime = when {
            name.endsWith(".png", ignoreCase = true) -> "image/png"
            name.endsWith(".webp", ignoreCase = true) -> "image/webp"
            else -> "image/jpeg"
        }

        // Android Q+ (scoped storage): use RELATIVE_PATH into Pictures/album
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/$album")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: return false

            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return false

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }
        return true
    }
}
