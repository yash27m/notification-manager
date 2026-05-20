// android/app/src/main/kotlin/com/example/notification_manager/NotificationListener.kt
package com.example.notification_manager

import android.app.Notification
import android.graphics.Bitmap
import android.graphics.drawable.Icon
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream

class NotificationListener : NotificationListenerService() {

    companion object {
        const val CHANNEL_NAME = "com.example.notification_manager/notifications"
        private var eventSink: EventChannel.EventSink? = null

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return
        val packageName = sbn.packageName ?: return
        if (packageName == applicationContext.packageName) return

        val data = HashMap<String, Any?>()
        data["action"] = "posted"
        data["packageName"] = packageName
        data["key"] = sbn.key
        data["timestamp"] = sbn.postTime
        data["isOngoing"] = sbn.isOngoing
        data["title"] = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        data["text"] = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        data["subText"] = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        data["bigText"] = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        data["conversationTitle"] = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString() ?: ""
        data["category"] = notification.category ?: ""

        // Large icon (avatar)
        try {
            val bitmap: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                extras.getParcelable<Icon>(Notification.EXTRA_LARGE_ICON)?.let { icon ->
                    val drawable = icon.loadDrawable(this) ?: return@let null
                    val w = drawable.intrinsicWidth.coerceAtMost(128)
                    val h = drawable.intrinsicHeight.coerceAtMost(128)
                    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                    val canvas = android.graphics.Canvas(bmp)
                    drawable.setBounds(0, 0, w, h)
                    drawable.draw(canvas)
                    bmp
                }
            } else {
                @Suppress("DEPRECATION")
                extras.getParcelable<Bitmap>("android.largeIcon")
            }
            if (bitmap != null) {
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
                data["largeIcon"] = stream.toByteArray()
            }
        } catch (_: Exception) {}

        // Picture (expanded image)
        try {
            @Suppress("DEPRECATION")
            val picture = extras.getParcelable<Bitmap>(Notification.EXTRA_PICTURE)
            if (picture != null) {
                val scaled = Bitmap.createScaledBitmap(picture, picture.width.coerceAtMost(320), picture.height.coerceAtMost(320), true)
                val stream = ByteArrayOutputStream()
                scaled.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                data["picture"] = stream.toByteArray()
            }
        } catch (_: Exception) {}

        android.os.Handler(android.os.Looper.getMainLooper()).post { eventSink?.success(data) }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        sbn ?: return
        val extras = sbn.notification?.extras ?: return
        val packageName = sbn.packageName ?: return
        if (packageName == applicationContext.packageName) return

        val data = HashMap<String, Any?>()
        data["action"] = "removed"
        data["packageName"] = packageName
        data["key"] = sbn.key
        data["timestamp"] = sbn.postTime
        data["title"] = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        data["text"] = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        android.os.Handler(android.os.Looper.getMainLooper()).post { eventSink?.success(data) }
    }
}