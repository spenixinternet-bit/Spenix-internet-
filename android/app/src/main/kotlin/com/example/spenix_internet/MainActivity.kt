package com.example.spenix_internet

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"
    private val VPN_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "connect" -> {
                    val config = call.argument<String>("config")

                    if (config != null) {
                        requestVpnPermissionAndStart(
                            mode = "client",
                            config = config
                        )
                        result.success(true)
                    } else {
                        result.error(
                            "INVALID_CONFIG",
                            "Config is null",
                            null
                        )
                    }
                }

                "disconnect" -> {
                    stopVpnService()
                    result.success(true)
                }

                "startGateway" -> {
                    requestVpnPermissionAndStart(
                        mode = "server",
                        config = null
                    )
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

    private fun requestVpnPermissionAndStart(
        mode: String,
        config: String?
    ) {
        val intent = VpnService.prepare(this)

        if (intent != null) {
            // Android needs permission first
            startActivityForResult(
                intent,
                VPN_REQUEST_CODE
            )
        } else {
            // Permission was already granted
            startVpnService(mode, config)
        }
    }

    private fun startVpnService(
        mode: String,
        config: String?
    ) {
        val intent = Intent(
            this,
            SpenixVpnService::class.java
        ).apply {
            putExtra("mode", mode)

            if (config != null) {
                putExtra("config", config)
            }
        }

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

        if (requestCode == VPN_REQUEST_CODE &&
            resultCode == RESULT_OK
        ) {

            // Permission granted.
            // Gateway/client will be started
            // when the command is requested again.
        }
    }
}
