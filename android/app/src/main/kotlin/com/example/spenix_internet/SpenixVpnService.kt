package com.example.spenix_internet

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

class SpenixVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false

    companion object {
        const val TAG = "SpenixVPN"
        const val CHANNEL_ID = "spenix_vpn_channel"
        const val NOTIFICATION_ID = 1001
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        val mode = intent?.getStringExtra("mode") ?: "client"
        val config = intent?.getStringExtra("config")

        Log.d(TAG, "Spenix VPN command. Mode: $mode")

        // ============================================================
        // DISCONNECT
        // ============================================================
        if (mode == "disconnect") {

            Log.d(TAG, "Disconnecting Spenix VPN")

            stopVpnInterface()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }

            stopSelf()

            return START_NOT_STICKY
        }

        // ============================================================
        // STOP OLD VPN INTERFACE
        // ============================================================
        stopVpnInterface()

        // ============================================================
        // START FOREGROUND SERVICE
        // ============================================================
        startVpnForeground()

        // ============================================================
        // START CLIENT OR GATEWAY
        // ============================================================
        if (mode == "server") {
            startGateway()
        } else {
            startClient(config)
        }

        return START_NOT_STICKY
    }

    // ============================================================
    // FOREGROUND NOTIFICATION
    // ============================================================

    private fun startVpnForeground() {

        createNotificationChannel()

        val notification = createNotification()

        startForeground(
            NOTIFICATION_ID,
            notification
        )
    }

    // ============================================================
    // NOTIFICATION CHANNEL
    // ============================================================

    private fun createNotificationChannel() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                CHANNEL_ID,
                "Spenix VPN",
                NotificationManager.IMPORTANCE_LOW
            )

            channel.description = "Spenix VPN connection"

            val manager =
                getSystemService(NotificationManager::class.java)

            manager.createNotificationChannel(channel)
        }
    }

    // ============================================================
    // VPN NOTIFICATION
    // ============================================================

    private fun createNotification(): Notification {

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Spenix VPN")
                .setContentText("Spenix VPN is running")
                .setSmallIcon(android.R.drawable.ic_secure)
                .setOngoing(true)
                .build()

        } else {

            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Spenix VPN")
                .setContentText("Spenix VPN is running")
                .setSmallIcon(android.R.drawable.ic_secure)
                .setOngoing(true)
                .build()
        }
    }

    // ============================================================
    // CLIENT MODE
    // ============================================================

    private fun startClient(config: String?) {

        try {

            Log.d(TAG, "Starting Spenix VPN client")

            val builder = Builder()

            // Virtual VPN address
            builder.addAddress(
                "10.8.0.2",
                32
            )

            // DNS
            builder.addDnsServer(
                "1.1.1.1"
            )

            builder.addDnsServer(
                "8.8.8.8"
            )

            // Route IPv4 traffic through VPN
            builder.addRoute(
                "0.0.0.0",
                0
            )

            builder.setMtu(1400)

            builder.setSession(
                "Spenix VPN"
            )

            vpnInterface = builder.establish()

            if (vpnInterface != null) {

                isRunning = true

                Log.d(
                    TAG,
                    "Spenix VPN interface established successfully"
                )

            } else {

                Log.e(
                    TAG,
                    "Failed to establish VPN interface"
                )

                stopSelf()
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Spenix VPN client error",
                e
            )

            stopVpnInterface()

            stopSelf()
        }
    }

    // ============================================================
    // GATEWAY MODE
    // ============================================================

    private fun startGateway() {

        try {

            Log.d(
                TAG,
                "Starting Spenix gateway mode"
            )

            val builder = Builder()

            // Gateway VPN address
            builder.addAddress(
                "10.8.0.1",
                24
            )

            // DNS
            builder.addDnsServer(
                "1.1.1.1"
            )

            builder.addDnsServer(
                "8.8.8.8"
            )

            // Route IPv4 traffic
            builder.addRoute(
                "0.0.0.0",
                0
            )

            builder.setMtu(1400)

            builder.setSession(
                "Spenix Gateway"
            )

            vpnInterface = builder.establish()

            if (vpnInterface != null) {

                isRunning = true

                Log.d(
                    TAG,
                    "Spenix gateway interface established"
                )

            } else {

                Log.e(
                    TAG,
                    "Failed to establish gateway interface"
                )

                stopSelf()
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Spenix gateway error",
                e
            )

            stopVpnInterface()

            stopSelf()
        }
    }

    // ============================================================
    // STOP VPN INTERFACE
    // ============================================================

    private fun stopVpnInterface() {

        try {

            vpnInterface?.close()

            Log.d(
                TAG,
                "VPN interface closed"
            )

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Error closing VPN interface",
                e
            )
        }

        vpnInterface = null
        isRunning = false
    }

    // ============================================================
    // VPN REVOKED
    // ============================================================

    override fun onRevoke() {

        Log.d(
            TAG,
            "VPN permission revoked"
        )

        stopVpnInterface()

        stopSelf()

        super.onRevoke()
    }

    // ============================================================
    // SERVICE DESTROYED
    // ============================================================

    override fun onDestroy() {

        Log.d(
            TAG,
            "Spenix VPN service destroyed"
        )

        stopVpnInterface()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {

            stopForeground(
                STOP_FOREGROUND_REMOVE
            )

        } else {

            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        super.onDestroy()
    }

    // ============================================================
    // VPN BIND
    // ============================================================

    override fun onBind(intent: Intent?) =
        super.onBind(intent)
}
