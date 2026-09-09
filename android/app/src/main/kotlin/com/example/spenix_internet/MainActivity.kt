package com.example.spenix_internet

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.util.Log

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.wireguard.android.backend.Backend
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config

import java.io.ByteArrayInputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "spenix_vpn"
    private val VPN_REQUEST_CODE = 1001

    private lateinit var backend: Backend

    private var pendingConnect = false

    private val spenixTunnel = object : Tunnel {

        override fun getName(): String {
            return "Spenix"
        }

        override fun onStateChange(newState: Tunnel.State) {
            Log.d("SpenixVPN", "WireGuard state: $newState")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        backend = GoBackend(this)
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
                    pendingConnect = true
                    requestVpnPermission()
                    result.success(true)
                }

                "disconnect" -> {
                    pendingConnect = false
                    disconnectWireGuard()
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestVpnPermission() {

        val intent = VpnService.prepare(this)

        if (intent != null) {

            startActivityForResult(
                intent,
                VPN_REQUEST_CODE
            )

        } else {

            startWireGuard()
        }
    }

    private fun startWireGuard() {

        if (!pendingConnect) {
            return
        }

        Thread {

            try {

                Log.d(
                    "SpenixVPN",
                    "Starting Spenix VPN..."
                )

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

                val config = Config.parse(
                    ByteArrayInputStream(
                        configText.toByteArray(
                            Charsets.UTF_8
                        )
                    )
                )

                backend.setState(
                    spenixTunnel,
                    Tunnel.State.UP,
                    config
                )

                Log.d(
                    "SpenixVPN",
                    "Spenix VPN connected successfully"
                )

            } catch (e: Exception) {

                Log.e(
                    "SpenixVPN",
                    "Spenix VPN connection failed",
                    e
                )
            }

        }.start()
    }

    private fun disconnectWireGuard() {

        Thread {

            try {

                backend.setState(
                    spenixTunnel,
                    Tunnel.State.DOWN,
                    null
                )

                Log.d(
                    "SpenixVPN",
                    "Spenix VPN disconnected"
                )

            } catch (e: Exception) {

                Log.e(
                    "SpenixVPN",
                    "Disconnect error",
                    e
                )
            }

        }.start()
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

            if (
                resultCode == RESULT_OK &&
                pendingConnect
            ) {

                startWireGuard()

            } else {

                pendingConnect = false
            }
        }
    }
}
