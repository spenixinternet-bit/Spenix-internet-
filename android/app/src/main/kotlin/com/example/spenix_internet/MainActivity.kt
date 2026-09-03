package com.example.spenix_internet

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "spenix_vpn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connect" -> {
                        val config = call.argument<String>("config")
                        if (config != null) {
                            startVpnService(config)
                            result.success(true)
                        } else {
                            result.error("INVALID_CONFIG", "Config is null", null)
                        }
                    }
                    "disconnect" -> {
                        stopVpnService()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startVpnService(config: String) {
        val intent = Intent(this, SpenixVpnService::class.java).apply {
            putExtra("config", config)
        }
        startService(intent)
    }

    private fun stopVpnService() {
        val intent = Intent(this, SpenixVpnService::class.java)
        stopService(intent)
    }
}
