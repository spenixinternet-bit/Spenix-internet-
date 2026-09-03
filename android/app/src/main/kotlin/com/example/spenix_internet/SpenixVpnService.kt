package com.example.spenix_internet

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

class SpenixVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var isServerMode = false

    companion object {
        const val TAG = "SpenixVPN"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val mode = it.getStringExtra("mode") ?: "client"
            isServerMode = mode == "server"
            val config = it.getStringExtra("config")
            if (isServerMode) {
                startServer()
            } else if (config != null) {
                connect(config)
            }
        }
        return START_STICKY
    }

    // Client mode – connect to a remote server (existing)
    private fun connect(config: String) {
        try {
            val builder = Builder()
            builder.setAddress("10.0.0.2", 32)
            builder.addDnsServer("1.1.1.1")
            builder.addDnsServer("8.8.8.8")
            builder.addRoute("0.0.0.0", 0)
            builder.setMtu(1500)
            builder.setSession("Spenix VPN")
            builder.setBlocking(true)

            vpnInterface = builder.establish()
            Log.d(TAG, "VPN client connected")
        } catch (e: Exception) {
            Log.e(TAG, "VPN client failed: ${e.message}")
            throw e
        }
    }

    // Server mode – listen for incoming connections (Gateway)
    private fun startServer() {
        try {
            // Show persistent notification to keep service alive
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "gateway_channel",
                    "Spenix Gateway",
                    NotificationManager.IMPORTANCE_LOW
                )
                val manager = getSystemService(NotificationManager::class.java)
                manager.createNotificationChannel(channel)
                val notification = Notification.Builder(this, "gateway_channel")
                    .setContentTitle("Spenix Gateway")
                    .setContentText("Sharing internet via VPN")
                    .setSmallIcon(android.R.drawable.ic_menu_share)
                    .build()
                startForeground(1, notification)
            }

            val builder = Builder()
            // Server address (gateway)
            builder.setAddress("10.0.0.1", 24)
            builder.addDnsServer("1.1.1.1")
            builder.addDnsServer("8.8.8.8")
            builder.addRoute("0.0.0.0", 0)
            builder.setMtu(1500)
            builder.setSession("Spenix Gateway")
            builder.setBlocking(true)

            vpnInterface = builder.establish()
            Log.d(TAG, "Gateway started – sharing internet")

            // ⚠️ For full internet sharing, you need to NAT traffic.
            // This requires advanced routing (iptables/tun2socks).
            // For now, the tunnel is established; actual forwarding needs extra setup.
        } catch (e: Exception) {
            Log.e(TAG, "Gateway start failed: ${e.message}")
        }
    }

    override fun onDestroy() {
        vpnInterface?.close()
        vpnInterface = null
        Log.d(TAG, "VPN stopped")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?) = null
}
