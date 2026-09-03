package com.example.spenix_internet

import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class SpenixVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null

    companion object {
        const val TAG = "SpenixVPN"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val config = it.getStringExtra("config")
            if (config != null) {
                connect(config)
            }
        }
        return START_STICKY
    }

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
            Log.d(TAG, "VPN established successfully")
        } catch (e: Exception) {
            Log.e(TAG, "VPN failed: ${e.message}")
            throw e
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
