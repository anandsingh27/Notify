package com.example.wa_filter

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

/**
 * Listens for system notifications from com.whatsapp.
 * Forwards each notification's title + text to Flutter via the static [eventSink].
 *
 * The sink is set by MainActivity when Flutter starts listening on the EventChannel.
 * Because the service and MainActivity share the same process, the companion-object
 * reference is safe without any IPC.
 */
class WaNotificationService : NotificationListenerService() {

    companion object {
        const val WA_PACKAGE = "com.whatsapp"

        /** Set by MainActivity when Dart subscribes; cleared on unsubscribe. */
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        private val mainHandler = Handler(Looper.getMainLooper())
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        val sink = eventSink ?: return
        if (sbn == null || sbn.packageName != WA_PACKAGE) return

        val notification = sbn.notification ?: return

        // Skip group-summary notifications (the "N messages from X contacts" summary)
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = notification.extras ?: return
        val title = extras.getCharSequence("android.title")?.toString()?.trim() ?: return
        val text  = extras.getCharSequence("android.text")?.toString()?.trim()  ?: return

        // Skip empty or WhatsApp UI noise
        if (title.isEmpty() || text.isEmpty()) return
        if (text.contains("messages from") && text.contains("chats")) return

        val data = mapOf(
            "title" to title,
            "text"  to text,
            "time"  to System.currentTimeMillis()
        )

        mainHandler.post { sink.success(data) }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        // No action needed
    }
}
