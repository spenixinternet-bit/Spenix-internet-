import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'gateway_service.dart';

class VpnService {
  static const MethodChannel _channel =
      MethodChannel('spenix_vpn');

  static final RxBool status = false.obs;

  static final RxString message =
      'Disconnected'.obs;

  static bool get isConnected {
    return status.value;
  }

  static Future<bool> connect({
    String? username,
    String? password,
  }) async {
    try {
      status.value = false;
      message.value =
          'Checking phone internet...';

      final result =
          await _channel.invokeMethod('connect');

      if (result != true) {
        status.value = false;
        message.value =
            'Spenix VPN connection failed.';
        return false;
      }

      message.value =
          'Checking Spenix gateway...';

      /*
       * The gateway API is on 10.8.0.1.
       *
       * That address is available through the
       * WireGuard tunnel, so we check it AFTER
       * the VPN tunnel has successfully started.
       */
      final gateway =
          await GatewayService.check();

      if (!gateway.online) {
        await disconnect();

        status.value = false;

        message.value =
            'Spenix gateway is offline.';

        return false;
      }

      if (!gateway.internetWorking) {
        await disconnect();

        status.value = false;

        message.value =
            'Spenix gateway has no internet.';

        return false;
      }

      status.value = true;

      message.value =
          'Spenix VPN connected';

      return true;
    } on PlatformException catch (e) {
      status.value = false;

      message.value =
          e.message ??
              'Spenix VPN connection failed.';

      return false;
    } catch (e) {
      status.value = false;

      message.value =
          'VPN error: $e';

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
    } on PlatformException catch (e) {
      status.value = false;

      message.value =
          e.message ??
              'Disconnect failed.';

      return false;
    } catch (_) {
      status.value = false;

      message.value =
          'Disconnect failed.';

      return false;
    }
  }

  static Future<bool> startGateway() async {
    try {
      final result =
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
      final result =
          await _channel.invokeMethod(
        'stopGateway',
      );

      return result == true;
    } catch (_) {
      return false;
    }
  }
}
