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

  static GatewayStatus? lastGatewayStatus;

  static bool get isConnected =>
      status.value;

  static Future<bool> connect({
    String? username,
    String? password,
  }) async {
    try {
      status.value = false;

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

      status.value = true;

      message.value =
          'Spenix VPN connected';

      /*
       * IMPORTANT:
       * Do NOT disconnect the VPN just because
       * the gateway API takes time to respond.
       *
       * The VPN tunnel is now running.
       * The dashboard will continue checking
       * the gateway separately.
       */

      await Future.delayed(
        const Duration(seconds: 2),
      );

      lastGatewayStatus =
          await GatewayService.check();

      if (lastGatewayStatus != null &&
          lastGatewayStatus!.online) {
        message.value =
            'Connected to Spenix gateway';
      } else {
        message.value =
            'VPN connected. Checking gateway...';
      }

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

  static Future<GatewayStatus> refreshGateway() async {
    final GatewayStatus gateway =
        await GatewayService.check();

    lastGatewayStatus = gateway;

    return gateway;
  }

  static Future<bool> disconnect() async {
    try {
      await _channel.invokeMethod(
        'disconnect',
      );

      status.value = false;

      message.value =
          'Disconnected';

      lastGatewayStatus = null;

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
