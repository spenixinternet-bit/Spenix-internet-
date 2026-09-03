import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VpnService {
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Future<void> connect({
    required String username,
    required String password,
  }) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No network bars. Please make sure you have signal.');
    }

    // 👇 CHANGE THESE TWO
    const String gatewayIp = 'YOUR_GATEWAY_PUBLIC_IP';   // e.g., 102.0.0.1
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
