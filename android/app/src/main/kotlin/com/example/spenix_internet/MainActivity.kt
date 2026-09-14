package com.example.spenix_internet

import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Bundle
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config

import java.io.BufferedReader
import java.io.StringReader
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"

    private val VPN_REQUEST_CODE = 1001

    private lateinit var backend: GoBackend

    private var tunnel: Tunnel? = null

    private var pendingConnect = false

    private var pendingConnectResult:
        MethodChannel.Result? = null

    private val wireGuardExecutor:
        ExecutorService =
        Executors.newSingleThreadExecutor()

    private val mainHandler =
        Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(
            flutterEngine
        )

        backend = GoBackend(this)

        MethodChannel(
            flutterEngine
                .dartExecutor
                .binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "connect" -> {

                    if (!hasWorkingInternet()) {

                        result.error(
                            "NO_INTERNET",
                            "Phone internet/mobile data is not available.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    if (pendingConnect) {

                        result.error(
                            "ALREADY_CONNECTING",
                            "VPN connection is already being started.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    pendingConnect = true

                    pendingConnectResult =
                        result

                    val intent =
                        VpnService.prepare(
                            this
                        )

                    if (intent != null) {

                        startActivityForResult(
                            intent,
                            VPN_REQUEST_CODE
                        )

                    } else {

                        startWireGuard()
                    }
                }

                "disconnect" -> {

                    pendingConnect = false

                    pendingConnectResult =
                        null

                    wireGuardExecutor.execute {

                        try {

                            tunnel?.let {

                                backend.setState(
                                    it,
                                    Tunnel.State.DOWN,
                                    null
                                )
                            }

                            tunnel = null

                            mainHandler.post {

                                result.success(true)
                            }

                        } catch (e: Exception) {

                            mainHandler.post {

                                result.error(
                                    "DISCONNECT_ERROR",
                                    e.javaClass.simpleName +
                                        ": " +
                                        (
                                            e.message
                                                ?: "Could not disconnect VPN."
                                        ),
                                    null
                                )
                            }
                        }
                    }
                }

                "startGateway" -> {

                    result.success(false)
                }

                "stopGateway" -> {

                    result.success(false)
                }

                else -> {

                    result.notImplemented()
                }
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
            connectivityManager
                .getNetworkCapabilities(
                    network
                )
                ?: return false

        return capabilities.hasCapability(
            NetworkCapabilities
                .NET_CAPABILITY_INTERNET
        ) &&
        capabilities.hasCapability(
            NetworkCapabilities
                .NET_CAPABILITY_VALIDATED
        )
    }

    private fun startWireGuard() {

        wireGuardExecutor.execute {

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
                            StringReader(
                                configText
                            )
                        )
                    )

                if (tunnel == null) {

                    tunnel =
                        object : Tunnel {

                            override fun getName():
                                String {
                                return "Spenix"
                            }

                            override fun onStateChange(
                                newState:
                                    Tunnel.State
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

                mainHandler.post {

                    pendingConnectResult?.success(
                        true
                    )

                    pendingConnectResult =
                        null
                }

            } catch (e: Exception) {

                pendingConnect = false

                val errorMessage =
                    e.javaClass.simpleName +
                        ": " +
                        (
                            e.message
                                ?: "Unknown WireGuard error"
                        )

                mainHandler.post {

                    pendingConnectResult?.error(
                        "VPN_ERROR",
                        errorMessage,
                        null
                    )

                    pendingConnectResult =
                        null
                }
            }
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

        if (
            requestCode !=
                VPN_REQUEST_CODE
        ) {
            return
        }

        if (
            resultCode == RESULT_OK &&
            pendingConnect
        ) {

            startWireGuard()

        } else {

            pendingConnect = false

            pendingConnectResult?.error(
                "VPN_PERMISSION_DENIED",
                "VPN permission was not granted.",
                null
            )

            pendingConnectResult = null
        }
    }

    override fun onDestroy() {

        try {

            wireGuardExecutor.execute {

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
            }

        } catch (_: Exception) {
        }

        pendingConnect = false

        pendingConnectResult = null

        wireGuardExecutor.shutdownNow()

        super.onDestroy()
    }
}
