// ✅ IMPORT THE PACKAGE
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VpnService {
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Future<void> connect({
    required String username,
    required String password,
  }) async {
    // Check network bars
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No network bars. Please make sure you have signal.');
    }

    // ============================================================
    // 👇 CHANGE THESE TO YOUR SETUP
    // ============================================================
    const String gatewayIp = 'YOUR_PUBLIC_IP';   // Your public IP (e.g., 102.0.0.1)
    const int vpnPort = 1194;
    const String caCert = '''
-----BEGIN CERTIFICATE-----
MIID... (paste your CA certificate here)
-----END CERTIFICATE-----
''';

    final config = '''
client
dev tun
proto udp
remote $gatewayIp $vpnPort
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

    // ✅ USE THE CORRECT CLASS NAME: OpenVpnFlutter (capital O, V, P, N)
    await OpenVpnFlutter.startVpn(config);
    _isConnected = true;
  }

  static Future<void> disconnect() async {
    await OpenVpnFlutter.stopVpn();
    _isConnected = false;
  }

  // Real-time status stream
  static Stream<bool> get status async* {
    await for (var event in OpenVpnFlutter.status) {
      if (event == VpnStatus.connected) {
        _isConnected = true;
      } else if (event == VpnStatus.disconnected) {
        _isConnected = false;
      }
      yield _isConnected;
    }
  }
}
