package com.example.spenix_internet

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"
    private val VPN_REQUEST_CODE = 1001

    private var pendingMode: String = "client"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "connect" -> {

                    pendingMode = "client"

                    requestVpnPermissionAndStart()

                    result.success(true)
                }

                "disconnect" -> {

                    stopVpnService()

                    result.success(true)
                }

                "startGateway" -> {

                    pendingMode = "server"

                    requestVpnPermissionAndStart()

                    result.success(true)
                }

                "stopGateway" -> {

                    stopVpnService()

                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

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

    private fun startVpnService() {

        val intent = Intent(
            this,
            SpenixVpnService::class.java
        )

        intent.putExtra(
            "mode",
            pendingMode
        )

        startService(intent)
    }

    private fun stopVpnService() {

        val intent = Intent(
            this,
            SpenixVpnService::class.java
        )

        stopService(intent)
    }

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

            startVpnService()
        }
    }
}
