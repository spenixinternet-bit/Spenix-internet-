package com.example.spenix_internet

import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import java.io.BufferedReader
import java.io.StringReader

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"
    private val VPN_REQUEST_CODE = 1001

    private lateinit var backend: GoBackend

    private var tunnel: Tunnel? = null
    private var pendingConnect = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        backend = GoBackend(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "connect" -> {
                    if (!hasWorkingInternet()) {
                        result.error(
                            "NO_INTERNET",
                            "Mobile data/internet is not available.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    pendingConnect = true

                    val intent = VpnService.prepare(this)

                    if (intent != null) {
                        startActivityForResult(
                            intent,
                            VPN_REQUEST_CODE
                        )
                    } else {
                        startWireGuard(result)
                    }

                    result.success(true)
                }

                "disconnect" -> {
                    pendingConnect = false

                    try {
                        tunnel?.let {
                            backend.setState(
                                it,
                                Tunnel.State.DOWN,
                                null
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {
                        result.error(
                            "DISCONNECT_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "startGateway" -> {
                    result.success(false)
                }

                "stopGateway" -> {
                    result.success(false)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasWorkingInternet(): Boolean {

        val connectivityManager =
            getSystemService(
                ConnectivityManager::class.java
            )

        val network =
            connectivityManager.activeNetwork
                ?: return false

        val capabilities =
            connectivityManager.getNetworkCapabilities(network)
                ?: return false

        return capabilities.hasCapability(
            NetworkCapabilities.NET_CAPABILITY_INTERNET
        ) &&
        capabilities.hasCapability(
            NetworkCapabilities.NET_CAPABILITY_VALIDATED
        )
    }

    private fun startWireGuard(
        result: MethodChannel.Result? = null
    ) {

        try {

            val configText = """
                [Interface]
                PrivateKey = 6M4lNVQajP6/Hjc8Js+Zz71RfON7n/EzRAN2cfEhoHk=
                Address = 10.8.0.2/32
                DNS = 1.1.1.1
                MTU = 1380

                [Peer]
                PublicKey = 3YnmBNDVFlbWDcBDLuLoU7I2FN+zK0FN4pkfOLZ97X0=
                AllowedIPs = 0.0.0.0/0
                Endpoint = spenixvpn.duckdns.org:51820
                PersistentKeepalive = 25
            """.trimIndent()

            val config =
                Config.parse(
                    BufferedReader(
                        StringReader(configText)
                    )
                )

            if (tunnel == null) {

                tunnel = object : Tunnel {

                    override fun getName(): String {
                        return "Spenix"
                    }

                    override fun onStateChange(
                        newState: Tunnel.State
                    ) {
                    }
                }
            }

            backend.setState(
                tunnel!!,
                Tunnel.State.UP,
                config
            )

            pendingConnect = false

            result?.success(true)

        } catch (e: Exception) {

            pendingConnect = false

            result?.error(
                "VPN_ERROR",
                e.message,
                null
            )
        }
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

        if (requestCode == VPN_REQUEST_CODE) {

            if (resultCode == RESULT_OK &&
                pendingConnect
            ) {
                startWireGuard()
            } else {
                pendingConnect = false
            }
        }
    }

    override fun onDestroy() {

        try {

            tunnel?.let {
                backend.setState(
                    it,
                    Tunnel.State.DOWN,
                    null
                )
            }

        } catch (_: Exception) {
        }

        super.onDestroy()
    }
}
