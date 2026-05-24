package com.example.field_guard_re

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

class MainActivity : FlutterActivity() {
    companion object {
        // PHASE 3 PROOF channel — register/remove a single OS geofence.
        private const val CHANNEL = "field_guard/os_geofence"
        private const val FENCE_ID = "active_task_fence"
    }

    private val geofencingClient: GeofencingClient by lazy {
        LocationServices.getGeofencingClient(this)
    }

    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(this, GeofenceBroadcastReceiver::class.java)
        PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "registerGeofence" -> {
                        val lat = call.argument<Double>("lat")
                        val lng = call.argument<Double>("lng")
                        val radius = (call.argument<Double>("radius") ?: 30.0).toFloat()
                        if (lat == null || lng == null) {
                            result.error("ARGS", "lat/lng required", null)
                            return@setMethodCallHandler
                        }
                        registerGeofence(lat, lng, radius, result)
                    }
                    "removeGeofence" -> {
                        geofencingClient.removeGeofences(listOf(FENCE_ID))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @SuppressLint("MissingPermission")
    private fun registerGeofence(
        lat: Double,
        lng: Double,
        radius: Float,
        result: MethodChannel.Result,
    ) {
        val geofence = Geofence.Builder()
            .setRequestId(FENCE_ID)
            .setCircularRegion(lat, lng, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(
                Geofence.GEOFENCE_TRANSITION_ENTER or
                    Geofence.GEOFENCE_TRANSITION_EXIT,
            )
            .build()

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        // Replace any existing fence first, then add the new one.
        geofencingClient.removeGeofences(listOf(FENCE_ID)).addOnCompleteListener {
            geofencingClient.addGeofences(request, geofencePendingIntent)
                .addOnSuccessListener { result.success(true) }
                .addOnFailureListener { e ->
                    result.error("ADD_FAILED", e.message, null)
                }
        }
    }
}
