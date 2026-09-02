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
    // CHANGE THIS TO YOUR GATEWAY IP
    // ============================================================
    const String gatewayIp = 'YOUR_GATEWAY_IP'; // 👈 REPLACE WITH YOUR IP
    const int vpnPort = 1194;
    const String vpnProtocol = 'udp';

    // Build OpenVPN configuration
    final config = '''
client
dev tun
proto $vpnProtocol
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
-----BEGIN CERTIFICATE-----
YOUR_CA_CERT_HERE
-----END CERTIFICATE-----
</ca>
''';

    // Connect using OpenVPN Flutter
    await OpenVpnFlutter.startVpn(config);
    _isConnected = true;
  }

  static Future<void> disconnect() async {
    await OpenVpnFlutter.stopVpn();
    _isConnected = false;
  }

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
