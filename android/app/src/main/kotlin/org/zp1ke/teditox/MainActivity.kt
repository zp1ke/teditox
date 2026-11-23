package org.zp1ke.teditox

import android.content.ClipData
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.zp1ke.teditox/content_uri"
    private val PICK_FILE_REQUEST = 1001
    private val CREATE_FILE_REQUEST = 1002

    private var pendingResult: MethodChannel.Result? = null
    private var contentChannel: MethodChannel? = null
    private var pendingIncoming: HashMap<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        contentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        contentChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFile" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "text/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                            "text/plain",
                            "text/csv",
                            "application/json",
                            "text/markdown",
                            "text/*"
                        ))
                    }
                    startActivityForResult(intent, PICK_FILE_REQUEST)
                }
                "createFile" -> {
                    val fileName = call.argument<String>("fileName") ?: "new_file.txt"
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                            "text/plain",
                            "text/csv",
                            "application/json",
                            "text/markdown"
                        ))
                    }
                    startActivityForResult(intent, CREATE_FILE_REQUEST)
                }
                "readFromUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        val bytes = contentResolver.openInputStream(uri)?.use { input ->
                            val buffer = ByteArrayOutputStream()
                            val data = ByteArray(8192)
                            var count: Int
                            while (input.read(data).also { count = it } != -1) {
                                buffer.write(data, 0, count)
                            }
                            buffer.toByteArray()
                        }
                        result.success(bytes)
                    } catch (e: Exception) {
                        result.error("READ_ERROR", "Failed to read from URI: ${e.message}", null)
                    }
                }
                "writeToUri" -> {
                    val uriString = call.argument<String>("uri")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (uriString == null || bytes == null) {
                        result.error("INVALID_ARGUMENT", "URI and bytes are required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        contentResolver.openOutputStream(uri)?.use { output ->
                            output.write(bytes)
                            output.flush()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WRITE_ERROR", "Failed to write to URI: ${e.message}", null)
                    }
                }
                "getDisplayName" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        val displayName = getDisplayNameFromUri(uri)
                        result.success(displayName)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", "Failed to get display name: ${e.message}", null)
                    }
                }
                "takePersistableUriPermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("INVALID_ARGUMENT", "URI is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = Uri.parse(uriString)
                        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        contentResolver.takePersistableUriPermission(uri, flags)
                        result.success(true)
                    } catch (e: Exception) {
                        // Permission might already be taken or not available
                        result.success(false)
                    }
                }
                "shareFile" -> {
                    val path = call.argument<String>("path")
                    val text = call.argument<String>("text") ?: ""
                    if (path == null) {
                        result.error("INVALID_ARGUMENT", "path is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(path)
                        val uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file,
                        )
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_TEXT, text)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            clipData = ClipData.newRawUri("shared", uri)
                        }
                        startActivity(Intent.createChooser(send, null))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                "takeIncomingFile" -> {
                    val pending = pendingIncoming
                    pendingIncoming = null
                    result.success(pending)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (pendingResult == null) return

        when (requestCode) {
            PICK_FILE_REQUEST, CREATE_FILE_REQUEST -> {
                if (resultCode == RESULT_OK && data != null) {
                    val uri = data.data
                    if (uri != null) {
                        try {
                            // Take persistable permission
                            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                            contentResolver.takePersistableUriPermission(uri, flags)

                            // Get display name
                            val displayName = getDisplayNameFromUri(uri)

                            // Return result
                            val resultMap = hashMapOf(
                                "uri" to uri.toString(),
                                "displayName" to displayName
                            )
                            pendingResult?.success(resultMap)
                        } catch (e: Exception) {
                            pendingResult?.error("ERROR", "Failed to process URI: ${e.message}", null)
                        }
                    } else {
                        pendingResult?.success(null)
                    }
                } else {
                    pendingResult?.success(null)
                }
                pendingResult = null
            }
        }
    }

    private fun getDisplayNameFromUri(uri: Uri): String? {
        val cursor: Cursor? = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    return it.getString(nameIndex)
                }
            }
        }
        return null
    }

    override fun getInitialRoute(): String = "/"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Stash the file before clearing it. GoRouter otherwise treats the
        // content:// URI as the route, and the share plugin then never sees it.
        captureIncoming(intent)
        scrubFileIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        captureIncoming(intent)
        scrubFileIntent(intent)
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun captureIncoming(intent: Intent?) {
        val uri = incomingUri(intent) ?: return
        rememberReadPermission(intent, uri)
        val payload = hashMapOf("uri" to uri.toString())
        usableDisplayName(uri)?.let { payload["displayName"] = it }
        intent?.type?.let { payload["mimeType"] = it }
        if (contentChannel == null) {
            pendingIncoming = payload
            return
        }
        contentChannel?.invokeMethod("onIncomingFile", payload)
    }

    private fun incomingUri(intent: Intent?): Uri? {
        if (intent == null) return null
        val data = intent.data
        if (data != null && isFileUri(data)) return data
        val stream = extraStream(intent)
        if (stream != null && isFileUri(stream)) return stream
        val clip = intent.clipData
        if (clip != null && clip.itemCount > 0) {
            val clipUri = clip.getItemAt(0).uri
            if (clipUri != null && isFileUri(clipUri)) return clipUri
        }
        return null
    }

    private fun extraStream(intent: Intent): Uri? {
        return if (android.os.Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun isFileUri(uri: Uri): Boolean {
        return uri.scheme == "content" || uri.scheme == "file"
    }

    private fun usableDisplayName(uri: Uri): String? {
        val queried = getDisplayNameFromUri(uri)?.trim()
        if (!queried.isNullOrEmpty()) return queried
        if (uri.scheme != "file") return null
        val segment = uri.lastPathSegment?.trim()
        if (segment.isNullOrEmpty()) return null
        return segment
    }

    private fun rememberReadPermission(intent: Intent?, uri: Uri) {
        if (uri.scheme != "content" || intent == null) return
        val flags = intent.flags and (
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        if (flags == 0) return
        try {
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: Exception) {
            // View grants are often temporary. The read still works this session.
        }
    }

    private fun scrubFileIntent(intent: Intent?) {
        if (intent == null) return
        val uri = intent.data
        if (uri != null && isFileUri(uri)) {
            intent.data = null
        }
        intent.removeExtra(Intent.EXTRA_STREAM)
        if (intent.clipData != null) {
            intent.clipData = null
        }
    }
}
