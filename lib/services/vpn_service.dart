import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'gateway_service.dart';

class VpnService {
  static const MethodChannel _channel =
      MethodChannel('spenix_vpn');

  static final RxBool status = false.obs;

  static final RxString message =
      'Disconnected'.obs;

  static bool get isConnected =>
      status.value;

  static Future<bool> connect({
    String? username,
    String? password,
  }) async {
    try {
      status.value = false;

      // ----------------------------------------------------------
      // STEP 1: CHECK PHONE INTERNET
      // ----------------------------------------------------------

      message.value =
          'Checking phone internet...';

      final dynamic vpnResult =
          await _channel.invokeMethod('connect');

      if (vpnResult != true) {
        status.value = false;

        message.value =
            'WireGuard could not start.';

        return false;
      }

      // ----------------------------------------------------------
      // STEP 2: GIVE WIREGUARD TIME TO CONNECT
      // ----------------------------------------------------------

      message.value =
          'Connecting to Spenix gateway...';

      await Future.delayed(
        const Duration(seconds: 2),
      );

      // ----------------------------------------------------------
      // STEP 3: CHECK GATEWAY
      // ----------------------------------------------------------

      GatewayStatus? gateway;

      for (int attempt = 1; attempt <= 5; attempt++) {
        message.value =
            'Checking Spenix gateway... '
            '($attempt/5)';

        gateway =
            await GatewayService.check();

        if (gateway.online &&
            gateway.internetWorking) {
          break;
        }

        if (attempt < 5) {
          await Future.delayed(
            const Duration(seconds: 1),
          );
        }
      }

      // ----------------------------------------------------------
      // STEP 4: GATEWAY MUST BE ONLINE
      // ----------------------------------------------------------

      if (gateway == null ||
          !gateway.online) {
        await disconnect();

        message.value =
            'Spenix gateway is offline.';

        return false;
      }

      // ----------------------------------------------------------
      // STEP 5: GATEWAY MUST HAVE INTERNET
      // ----------------------------------------------------------

      if (!gateway.internetWorking) {
        await disconnect();

        message.value =
            'Spenix gateway has no internet.';

        return false;
      }

      // ----------------------------------------------------------
      // STEP 6: SUCCESS
      // ----------------------------------------------------------

      status.value = true;

      message.value =
          'Spenix VPN connected to gateway';

      return true;
    } on PlatformException catch (e) {
      status.value = false;

      message.value =
          e.message ??
              'WireGuard could not start.';

      return false;
    } catch (e) {
      status.value = false;

      message.value =
          'VPN connection error: $e';

      return false;
    }
  }

  static Future<bool> disconnect() async {
    try {
      await _channel.invokeMethod(
        'disconnect',
      );

      status.value = false;

      message.value =
          'Disconnected';

      return true;
    } catch (e) {
      status.value = false;

      message.value =
          'Disconnect failed: $e';

      return false;
    }
  }

  static Future<bool> startGateway() async {
    try {
      final dynamic result =
          await _channel.invokeMethod(
        'startGateway',
      );

      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopGateway() async {
    try {
      final dynamic result =
          await _channel.invokeMethod(
        'stopGateway',
      );

      return result == true;
    } catch (_) {
      return false;
    }
  }
}
