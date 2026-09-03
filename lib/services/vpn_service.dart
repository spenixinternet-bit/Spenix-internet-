import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class VpnService {
  static bool _isConnected = false;
  static const MethodChannel _channel = MethodChannel('spenix_vpn');

  static bool get isConnected => _isConnected;

  static Future<void> connect({
    required String username,
    required String password,
  }) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No network bars. Please make sure you have signal.');
    }

    // 👇 CHANGE THESE TO YOUR SETUP
    const String gatewayIp = 'YOUR_GATEWAY_PUBLIC_IP';
    const String caCert = '''
-----BEGIN CERTIFICATE-----
YOUR_CA_CERTIFICATE_HERE
-----END CERTIFICATE-----
''';

    final config = '''
client
dev tun
proto udp
remote $gatewayIp 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
auth-user-pass
<ca>
$caCert
</ca>
''';

    try {
      // ⚡ THIS TRIGGERS THE NATIVE VPN – THIS IS WHY THE PERMISSION DIALOG APPEARS!
      await _channel.invokeMethod('connect', {'config': config});
      _isConnected = true;
    } catch (e) {
      throw Exception('VPN connection failed: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
    } catch (e) {}
  }

  static Stream<bool> get status async* {
    while (true) {
      yield _isConnected;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
