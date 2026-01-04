package com.benimsehrim.app.core.firebase

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import com.benimsehrim.app.MainActivity
import com.benimsehrim.app.R
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class BenimSehrimFirebaseService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FirebaseService"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")
        
        // Send token to backend
        CoroutineScope(Dispatchers.IO).launch {
            // apiService.registerPushToken(PushTokenRequest(token, "android"))
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.d(TAG, "Message received: ${message.data}")

        val notification = message.notification
        val data = message.data

        val title = notification?.title ?: data["title"] ?: "Benim Şehrim"
        val body = notification?.body ?: data["body"] ?: ""
        val type = data["type"] ?: "default"

        val channelId = when (type) {
            "NEW_ORDER", "ORDER_STATUS" -> "benimsehrim_orders"
            "NEW_RIDE_CALL", "RIDE_STATUS" -> "benimsehrim_taxi"
            "CHAT_MESSAGE" -> "benimsehrim_chat"
            else -> "benimsehrim_default"
        }

        showNotification(title, body, channelId, data)
    }

    private fun showNotification(
        title: String,
        body: String,
        channelId: String,
        data: Map<String, String>
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            // Pass data to activity
            data.forEach { (key, value) -> putExtra(key, value) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
