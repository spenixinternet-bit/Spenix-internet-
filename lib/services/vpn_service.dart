import 'package:wireguard_flutter/wireguard_flutter.dart';
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
    // 👇 CHANGE THIS TO YOUR GATEWAY PUBLIC IP
    // ============================================================
    const String gatewayIp = 'YOUR_GATEWAY_IP';   // e.g., 102.0.0.1
    const int vpnPort = 51820;                     // WireGuard default port

    // Generate a client key pair (you can also use a fixed one)
    final privateKey = await WireGuardFlutter.generatePrivateKey();
    final publicKey = await WireGuardFlutter.generatePublicKey(privateKey);

    // Build WireGuard config
    final config = '''
[Interface]
Address = 10.0.0.2/24
PrivateKey = $privateKey
DNS = 1.1.1.1

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY   # 👈 Replace with your server's public key
Endpoint = $gatewayIp:$vpnPort
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
''';

    // Connect using WireGuard
    await WireGuardFlutter.startVpn(
      config: config,
      name: 'Spenix VPN',
    );
    _isConnected = true;
  }

  static Future<void> disconnect() async {
    await WireGuardFlutter.stopVpn();
    _isConnected = false;
  }

  static Stream<bool> get status async* {
    while (true) {
      final status = await WireGuardFlutter.getVpnStatus();
      yield status == VpnStatus.connected;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
