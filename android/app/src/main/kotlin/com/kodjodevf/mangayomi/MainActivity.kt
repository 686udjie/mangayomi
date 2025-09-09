package com.kodjodevf.mangayomi

import androidx.annotation.NonNull
import libmtorrentserver.Libmtorrentserver
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.embedding.android.FlutterActivity
import androidx.core.content.FileProvider
import android.content.Intent
import android.os.Build
import android.net.Uri
import java.io.File
import android.os.Environment
import android.webkit.MimeTypeMap
import android.media.MediaScannerConnection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.FileOutputStream
import java.io.OutputStream

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kodjodevf.mangayomi.libmtorrentserver",
            StandardMethodCodec.INSTANCE,
            flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    try {
                        val port = Libmtorrentserver.start(config)
                        result.success(port)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kodjodevf.mangayomi.apk_install",
            StandardMethodCodec.INSTANCE,
            flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    installApk(filePath)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kodjodevf.mangayomi.media_saver",
            StandardMethodCodec.INSTANCE,
            flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImage" -> {
                    val data = call.argument<ByteArray>("data")
                    val name = call.argument<String>("name") ?: "image_${System.currentTimeMillis()}.png"
                    CoroutineScope(Dispatchers.Main).launch {
                        val path = withContext(Dispatchers.IO) {
                            saveImageToPictures(data, name)
                        }
                        if (path != null) {
                            MediaScannerConnection.scanFile(
                                this@MainActivity,
                                arrayOf(path),
                                arrayOf(MimeTypeMap.getSingleton().getMimeTypeFromExtension(File(path).extension)),
                                null
                            )
                            result.success(path)
                        } else {
                            result.error("ERROR", "Failed to save image", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(filePath: String?) {
        if (filePath == null) return
        val file = File(filePath)
        val intent = Intent(Intent.ACTION_VIEW)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        } else {
            Uri.fromFile(file)
        }
        intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
        startActivity(intent)
    }

    private fun saveImageToPictures(data: ByteArray?, name: String): String? {
        if (data == null) return null
        return try {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val targetDir = File(picturesDir, "Mangayomi")
            if (!targetDir.exists()) targetDir.mkdirs()
            val targetFile = File(targetDir, name)
            val out: OutputStream = FileOutputStream(targetFile)
            out.use { it.write(data) }
            targetFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
