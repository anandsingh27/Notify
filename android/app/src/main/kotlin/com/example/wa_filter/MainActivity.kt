package com.example.wa_filter

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        /** Dart subscribes here to receive WhatsApp notifications as a stream. */
        const val NOTIFICATION_CHANNEL = "wafilter/notifications"

        /** Flutter calls into Kotlin through this channel (settings, status checks). */
        const val CONTROL_CHANNEL = "wafilter/control"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── EventChannel: WaNotificationService ──→ Flutter ─────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    WaNotificationService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    WaNotificationService.eventSink = null
                }
            })

        // ── MethodChannel: Flutter ──→ Kotlin control ─────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "isNotificationListenerEnabled" -> {
                        // Check if WaNotificationService is in the system's enabled list
                        val flat = Settings.Secure.getString(
                            contentResolver,
                            "enabled_notification_listeners"
                        )
                        val enabled = flat != null &&
                                flat.contains("$packageName/${WaNotificationService::class.java.canonicalName}")
                        result.success(enabled)
                    }

                    "openNotificationSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
