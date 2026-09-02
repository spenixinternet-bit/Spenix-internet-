import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VpnService {
  // ============================================================
  // CHANGE THIS TO YOUR GATEWAY IP
  // ============================================================
  static const String gatewayIp = 'YOUR_GATEWAY_IP'; // 👈 CHANGE THIS!

  static const String vpnPort = '1194';
  static const String vpnProtocol = 'udp';

  // ============================================================
  // CHECK IF PHONE HAS NETWORK BARS
  // ============================================================
  static Future<bool> hasNetworkBars() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ============================================================
  // CONNECT TO VPN
  // ============================================================
  static Future<void> connect({
    required String username,
    required String password,
  }) async {
    if (!await hasNetworkBars()) {
      throw Exception('No network bars. Please make sure you have signal.');
    }

    final profile = '''
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

    await OpenVpnFlutter.startVpn(profile);
  }

  // ============================================================
  // DISCONNECT FROM VPN
  // ============================================================
  static Future<void> disconnect() async {
    await OpenVpnFlutter.stopVpn();
  }

  // ============================================================
  // GET VPN STATUS
  // ============================================================
  static Stream<VpnStatus> get status => OpenVpnFlutter.status;
}
