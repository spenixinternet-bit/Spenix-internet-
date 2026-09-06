import 'package:flutter/services.dart';

class VpnService {
  static const MethodChannel _channel = MethodChannel('spenix_vpn');

  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  // ============================================================
  // CONNECT VPN
  // ============================================================
  static Future<void> connect({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _channel.invokeMethod(
        'connect',
        {
          'username': username,
          'password': password,
        },
      );

      if (result == true || result == 'connected') {
        _isConnected = true;
      }
    } on PlatformException catch (e) {
      throw Exception(
        e.message ?? 'Failed to start Spenix VPN',
      );
    } catch (e) {
      throw Exception(
        'VPN connection failed: $e',
      );
    }
  }

  // ============================================================
  // DISCONNECT VPN
  // ============================================================
  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
    } catch (e) {
      _isConnected = false;
    }
  }

  // ============================================================
  // VPN STATUS
  // ============================================================
  static Stream<bool> get status async* {
    while (true) {
      yield _isConnected;
      await Future.delayed(
        const Duration(seconds: 1),
      );
    }
  }

  // ============================================================
  // START GATEWAY
  // ============================================================
  static Future<void> startGateway() async {
    try {
      await _channel.invokeMethod('startGateway');
    } on PlatformException catch (e) {
      throw Exception(
        e.message ?? 'Failed to start Spenix gateway',
      );
    } catch (e) {
      throw Exception(
        'Failed to start gateway: $e',
      );
    }
  }

  // ============================================================
  // STOP GATEWAY
  // ============================================================
  static Future<void> stopGateway() async {
    try {
      await _channel.invokeMethod('stopGateway');
    } catch (e) {
      // Gateway may already be stopped.
    }
  }
}
