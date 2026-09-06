package com.example.spenix_internet

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"

    private var pendingMode = "client"

    private val vpnPermissionLauncher =
        registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->

            if (result.resultCode == RESULT_OK) {
                startVpnService()
            }
        }

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

                    requestVpnPermission()

                    // Tell Flutter the request was accepted.
                    result.success(true)
                }

                "disconnect" -> {

                    stopVpnService()

                    result.success(true)
                }

                "startGateway" -> {

                    pendingMode = "server"

                    requestVpnPermission()

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

    private fun requestVpnPermission() {

        try {

            val intent = VpnService.prepare(this)

            if (intent != null) {

                vpnPermissionLauncher.launch(intent)

            } else {

                startVpnService()
            }

        } catch (e: Exception) {

            e.printStackTrace()
        }
    }

    private fun startVpnService() {

        try {

            val intent = Intent(
                this,
                SpenixVpnService::class.java
            )

            intent.putExtra(
                "mode",
                pendingMode
            )

            startService(intent)

        } catch (e: Exception) {

            e.printStackTrace()
        }
    }

    private fun stopVpnService() {

        try {

            val intent = Intent(
                this,
                SpenixVpnService::class.java
            )

            stopService(intent)

        } catch (e: Exception) {

            e.printStackTrace()
        }
    }
}
