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

        Log.d(TAG, "Starting Spenix VPN. Mode: $mode")

        // Stop any previous VPN interface
        stopVpnInterface()

        // Start foreground service
        startVpnForeground()

        if (mode == "server") {
            startGateway()
        } else {
            startClient(config)
        }

        return START_STICKY
    }

    /**
     * Start the foreground notification.
     */
    private fun startVpnForeground() {

        createNotificationChannel()

        val notification = createNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification
            )
        } else {
            startForeground(
                NOTIFICATION_ID,
                notification
            )
        }
    }

    /**
     * Create notification channel.
     */
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

    /**
     * VPN notification.
     */
    private fun createNotification(): Notification {

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Spenix VPN")
                .setContentText("Spenix VPN is running")
                .setSmallIcon(android.R.drawable.ic_secure)
                .setOngoing(true)
                .build()

        } else {

            Notification.Builder(this)
                .setContentTitle("Spenix VPN")
                .setContentText("Spenix VPN is running")
                .setSmallIcon(android.R.drawable.ic_secure)
                .setOngoing(true)
                .build()
        }
    }

    /**
     * CLIENT MODE
     *
     * Creates the VPN interface on the Android phone.
     *
     * IMPORTANT:
     * This currently creates the VPN tunnel interface only.
     * It does NOT yet connect to an OpenVPN server.
     */
    private fun startClient(config: String?) {

        try {

            Log.d(TAG, "Starting Spenix VPN client")

            val builder = Builder()

            // Virtual VPN address
            builder.addAddress(
                "10.8.0.2",
                32
            )

            // DNS servers
            builder.addDnsServer(
                "1.1.1.1"
            )

            builder.addDnsServer(
                "8.8.8.8"
            )

            // Route all IPv4 traffic through VPN
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

    /**
     * GATEWAY MODE
     *
     * Creates a VPN interface on this Android device.
     *
     * IMPORTANT:
     * This is NOT yet a real VPN server.
     *
     * A real gateway will later need:
     *
     * Internet
     *      ↓
     * Spenix Gateway
     *      ↓
     * VPN tunnel
     *      ↓
     * Customer phone
     */
    private fun startGateway() {

        try {

            Log.d(TAG, "Starting Spenix gateway mode")

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

            // Route IPv4 traffic through VPN interface
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

    /**
     * Stop VPN interface.
     */
    private fun stopVpnInterface() {

        try {

            vpnInterface?.close()

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Error closing VPN interface",
                e
            )
        }

        vpnInterface = null
        isRunning = false

        Log.d(
            TAG,
            "Spenix VPN interface stopped"
        )
    }

    /**
     * Called when Android revokes VPN permission.
     */
    override fun onRevoke() {

        Log.d(
            TAG,
            "VPN permission revoked"
        )

        stopVpnInterface()
        stopSelf()

        super.onRevoke()
    }

    /**
     * Service destroyed.
     */
    override fun onDestroy() {

        Log.d(
            TAG,
            "Spenix VPN service destroyed"
        )

        stopVpnInterface()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        super.onDestroy()
    }

    /**
     * VpnService requires this method.
     */
    override fun onBind(intent: Intent?) =
        super.onBind(intent)
}
