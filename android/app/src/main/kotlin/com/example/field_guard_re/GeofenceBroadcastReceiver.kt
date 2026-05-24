package com.example.field_guard_re

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

/**
 * PHASE 3 PROOF (branch feat/os-geofence-wake):
 *
 * Receives OS geofence transitions from the platform's GeofencingClient. The
 * whole point of this proof is that Android delivers this intent — and runs
 * this code — even when the Flutter app has been FULLY killed / force-stopped,
 * which the sticky foreground service cannot survive.
 *
 * For now it just posts a heads-up notification so we can confirm on-device
 * that the OS really wakes us. If that holds, the next step is to start the
 * FlutterBackgroundService here so the existing high-accuracy detection takes
 * over.
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "os_geofence_proof"
        private const val NOTIF_ID = 9931
    }

    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) {
            notify(context, "OS geofence error", "code=${event.errorCode}")
            return
        }

        val transition = when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> "ENTER"
            Geofence.GEOFENCE_TRANSITION_EXIT -> "EXIT"
            Geofence.GEOFENCE_TRANSITION_DWELL -> "DWELL"
            else -> "UNKNOWN(${event.geofenceTransition})"
        }
        val ids = event.triggeringGeofences?.joinToString(",") { it.requestId } ?: "?"
        notify(context, "OS geofence: $transition", "fence=$ids (app may be killed)")
    }

    private fun notify(context: Context, title: String, body: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "OS Geofence (proof)",
                NotificationManager.IMPORTANCE_HIGH,
            )
            nm.createNotificationChannel(channel)
        }

        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notif = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_map)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()

        nm.notify(NOTIF_ID, notif)
    }
}
