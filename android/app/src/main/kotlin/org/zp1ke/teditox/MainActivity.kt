package org.zp1ke.teditox

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.zp1ke.teditox/content_uri"
    private val PICK_FILE_REQUEST = 1001
    private val CREATE_FILE_REQUEST = 1002

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle incoming file intents by clearing the data URI
        // This prevents GoRouter from trying to process content:// URIs as routes
        intent?.data?.let { uri ->
            if (uri.scheme == "content" || uri.scheme == "file") {
                // Clear the data URI to prevent it from being processed by the router
                // The actual file handling is done by IntentService via receive_sharing_intent
                intent.data = null
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Handle incoming file intents when app is already running
        intent.data?.let { uri ->
            if (uri.scheme == "content" || uri.scheme == "file") {
                intent.data = null
            }
        }
        setIntent(intent)
    }
}
