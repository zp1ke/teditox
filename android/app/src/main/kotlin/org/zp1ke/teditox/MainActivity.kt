package org.zp1ke.teditox

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
