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

    private var pendingMode: String? = null

    private val vpnPermissionLauncher =
        registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result ->

            if (result.resultCode == RESULT_OK) {

                val mode = pendingMode ?: "client"

                startVpnService(mode)

                pendingMode = null
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

                // ====================================================
                // CONNECT
                // ====================================================

                "connect" -> {

                    val username =
                        call.argument<String>("username")

                    val password =
                        call.argument<String>("password")

                    if (username == null ||
                        password == null
                    ) {

                        result.error(
                            "INVALID_LOGIN",
                            "Username or password is missing",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    requestVpnPermissionAndStart(
                        mode = "client"
                    )

                    result.success(true)
                }

                // ====================================================
                // DISCONNECT
                // ====================================================

                "disconnect" -> {

                    stopVpnService()

                    result.success(true)
                }

                // ====================================================
                // START GATEWAY
                // ====================================================

                "startGateway" -> {

                    requestVpnPermissionAndStart(
                        mode = "server"
                    )

                    result.success(true)
                }

                // ====================================================
                // STOP GATEWAY
                // ====================================================

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

    // ================================================================
    // REQUEST VPN PERMISSION
    // ================================================================

    private fun requestVpnPermissionAndStart(
        mode: String
    ) {

        pendingMode = mode

        val prepareIntent =
            VpnService.prepare(this)

        if (prepareIntent != null) {

            vpnPermissionLauncher.launch(
                prepareIntent
            )

        } else {

            startVpnService(mode)

            pendingMode = null
        }
    }

    // ================================================================
    // START SPENIX VPN SERVICE
    // ================================================================

    private fun startVpnService(
        mode: String
    ) {

        val intent = Intent(
            this,
            SpenixVpnService::class.java
        ).apply {

            putExtra(
                "mode",
                mode
            )
        }

        startService(intent)
    }

    // ================================================================
    // STOP SPENIX VPN SERVICE
    // ================================================================

    private fun stopVpnService() {

        val intent = Intent(
            this,
            SpenixVpnService::class.java
        )

        stopService(intent)
    }
}
