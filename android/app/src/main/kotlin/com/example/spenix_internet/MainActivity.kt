package com.example.spenix_internet

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"
    private val VPN_REQUEST_CODE = 1001

    private var pendingMode: String = "client"

    // Used to prevent a VPN from starting after
    // the user has already pressed Disconnect.
    private var disconnectRequested = false

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // ====================================================
                // CONNECT
                // ====================================================

                "connect" -> {

                    disconnectRequested = false

                    pendingMode = "client"

                    requestVpnPermissionAndStart()

                    result.success(true)
                }

                // ====================================================
                // DISCONNECT
                // ====================================================

                "disconnect" -> {

                    disconnectRequested = true

                    stopVpnService()

                    result.success(true)
                }

                // ====================================================
                // START GATEWAY
                // ====================================================

                "startGateway" -> {

                    disconnectRequested = false

                    pendingMode = "server"

                    requestVpnPermissionAndStart()

                    result.success(true)
                }

                // ====================================================
                // STOP GATEWAY
                // ====================================================

                "stopGateway" -> {

                    disconnectRequested = true

                    stopVpnService()

                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // ================================================================
    // REQUEST VPN PERMISSION
    // ================================================================

    private fun requestVpnPermissionAndStart() {

        val intent = VpnService.prepare(this)

        if (intent != null) {

            startActivityForResult(
                intent,
                VPN_REQUEST_CODE
            )

        } else {

            startVpnService()
        }
    }

    // ================================================================
    // START VPN SERVICE
    // ================================================================

    private fun startVpnService() {

        // Do not start the VPN if Disconnect was pressed.
        if (disconnectRequested) {
            return
        }

        val intent = Intent(
            this,
            SpenixVpnService::class.java
        )

        intent.putExtra(
            "mode",
            pendingMode
        )

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

            startForegroundService(intent)

        } else {

            @Suppress("DEPRECATION")
            startService(intent)
        }
    }

    // ================================================================
    // STOP VPN SERVICE
    // ================================================================

    private fun stopVpnService() {

        // First send an explicit disconnect command.
        val disconnectIntent = Intent(
            this,
            SpenixVpnService::class.java
        )

        disconnectIntent.action =
            SpenixVpnService.ACTION_DISCONNECT

        disconnectIntent.putExtra(
            "mode",
            "disconnect"
        )

        try {

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

                startForegroundService(
                    disconnectIntent
                )

            } else {

                @Suppress("DEPRECATION")
                startService(
                    disconnectIntent
                )
            }

        } catch (e: Exception) {

            // If the service is not running,
            // make sure Android still stops it.
        }

        // Also explicitly stop the service.
        try {

            stopService(
                disconnectIntent
            )

        } catch (e: Exception) {
            // Ignore.
        }
    }

    // ================================================================
    // VPN PERMISSION RESULT
    // ================================================================

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {

        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )

        if (
            requestCode == VPN_REQUEST_CODE &&
            resultCode == RESULT_OK
        ) {

            // Only start if the user has NOT pressed Disconnect.
            if (!disconnectRequested) {
                startVpnService()
            }
        }
    }

    // ================================================================
    // ACTIVITY DESTROYED
    // ================================================================

    override fun onDestroy() {

        super.onDestroy()
    }
}
