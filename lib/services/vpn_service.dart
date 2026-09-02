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

    // Simulate VPN connection – remove this when you add real VPN
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
    print('✅ VPN Connected (simulated)');
  }

  static Future<void> disconnect() async {
    _isConnected = false;
    print('🔴 VPN Disconnected');
  }

  static Stream<bool> get status async* {
    while (true) {
      yield _isConnected;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
