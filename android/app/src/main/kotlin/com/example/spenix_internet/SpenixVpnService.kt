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

        const val ACTION_CONNECT = "com.example.spenix_internet.CONNECT"
        const val ACTION_DISCONNECT = "com.example.spenix_internet.DISCONNECT"
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        val action = intent?.action
        val mode = intent?.getStringExtra("mode") ?: "client"
        val config = intent?.getStringExtra("config")

        Log.d(
            TAG,
            "onStartCommand action=$action mode=$mode"
        )

        // ============================================================
        // DISCONNECT
        // ============================================================

        if (
            action == ACTION_DISCONNECT ||
            mode == "disconnect"
        ) {

            Log.d(TAG, "DISCONNECT command received")

            disconnectVpn()

            return START_NOT_STICKY
        }

        // ============================================================
        // MAKE SURE ANY OLD VPN IS CLOSED
        // ============================================================

        stopVpnInterface()

        // ============================================================
        // START FOREGROUND SERVICE
        // ============================================================

        startVpnForeground()

        // ============================================================
        // START VPN
        // ============================================================

        if (mode == "server") {
            startGateway()
        } else {
            startClient(config)
        }

        return START_NOT_STICKY
    }

    // ============================================================
    // DISCONNECT VPN COMPLETELY
    // ============================================================

    private fun disconnectVpn() {

        Log.d(TAG, "Completely disconnecting Spenix VPN")

        // First close the actual VPN interface.
        stopVpnInterface()

        // Remove foreground notification.
        try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {

                stopForeground(
                    STOP_FOREGROUND_REMOVE
                )

            } else {

                @Suppress("DEPRECATION")
                stopForeground(true)
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Error removing foreground service",
                e
            )
        }

        // Stop this Android service completely.
        try {

            stopSelf()

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Error stopping service",
                e
            )
        }

        Log.d(
            TAG,
            "Spenix VPN disconnected completely"
        )
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
                getSystemService(
                    NotificationManager::class.java
                )

            manager.createNotificationChannel(channel)
        }
    }

    // ============================================================
    // VPN NOTIFICATION
    // ============================================================

    private fun createNotification(): Notification {

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            Notification.Builder(
                this,
                CHANNEL_ID
            )
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

            Log.d(
                TAG,
                "Starting Spenix VPN client"
            )

            val builder = Builder()

            builder.addAddress(
                "10.8.0.2",
                32
            )

            builder.addDnsServer(
                "1.1.1.1"
            )

            builder.addDnsServer(
                "8.8.8.8"
            )

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

                disconnectVpn()
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Spenix VPN client error",
                e
            )

            disconnectVpn()
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

            builder.addAddress(
                "10.8.0.1",
                24
            )

            builder.addDnsServer(
                "1.1.1.1"
            )

            builder.addDnsServer(
                "8.8.8.8"
            )

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

                disconnectVpn()
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Spenix gateway error",
                e
            )

            disconnectVpn()
        }
    }

    // ============================================================
    // STOP VPN INTERFACE
    // ============================================================

    private fun stopVpnInterface() {

        val oldInterface = vpnInterface

        vpnInterface = null
        isRunning = false

        if (oldInterface != null) {

            try {

                oldInterface.close()

                Log.d(
                    TAG,
                    "VPN interface closed successfully"
                )

            } catch (e: Exception) {

                Log.e(
                    TAG,
                    "Error closing VPN interface",
                    e
                )
            }
        } else {

            Log.d(
                TAG,
                "No VPN interface to close"
            )
        }
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

        try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {

                stopForeground(
                    STOP_FOREGROUND_REMOVE
                )

            } else {

                @Suppress("DEPRECATION")
                stopForeground(true)
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Error stopping foreground on revoke",
                e
            )
        }

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

        // VERY IMPORTANT:
        // Always close the VPN interface when Android destroys
        // the service.

        stopVpnInterface()

        try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {

                stopForeground(
                    STOP_FOREGROUND_REMOVE
                )

            } else {

                @Suppress("DEPRECATION")
                stopForeground(true)
            }

        } catch (e: Exception) {

            Log.e(
                TAG,
                "Error stopping foreground service",
                e
            )
        }

        super.onDestroy()
    }

    // ============================================================
    // VPN BIND
    // ============================================================

    override fun onBind(intent: Intent?) =
        super.onBind(intent)
}
