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
      message.value = 'Checking internet...';

      final dynamic result =
          await _channel.invokeMethod('connect');

      if (result != true) {
        status.value = false;
        message.value = 'VPN connection failed.';
        return false;
      }

      message.value =
          'Checking Spenix gateway...';

      final GatewayStatus gateway =
          await GatewayService.check();

      if (!gateway.online) {
        await disconnect();

        message.value =
            'Spenix gateway is offline.';

        return false;
      }

      if (!gateway.internetWorking) {
        await disconnect();

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
          e.message ?? 'VPN connection failed.';

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
      await _channel.invokeMethod('disconnect');

      status.value = false;
      message.value = 'Disconnected';

      return true;
    } catch (e) {
      status.value = false;
      message.value = 'Disconnect failed.';

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
    } catch (e) {
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
    } catch (e) {
      return false;
    }
  }
}
