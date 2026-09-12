import 'package:flutter/services.dart';
import 'package:get/get.dart';

class VpnService extends GetxService {
  static const MethodChannel _channel =
      MethodChannel('spenix_vpn');

  final RxBool status = false.obs;
  final RxString message = 'Disconnected'.obs;

  Future<bool> connect() async {
    try {
      message.value = 'Checking internet...';

      final result = await _channel.invokeMethod('connect');

      if (result == true) {
        status.value = true;
        message.value = 'Spenix VPN connected';
        return true;
      }

      status.value = false;
      message.value = 'Connection failed';
      return false;

    } on PlatformException catch (e) {
      status.value = false;
      message.value = e.message ?? 'VPN connection failed';
      return false;

    } catch (e) {
      status.value = false;
      message.value = 'VPN error';
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');

      status.value = false;
      message.value = 'Disconnected';

      return true;

    } catch (e) {
      message.value = 'Disconnect failed';
      return false;
    }
  }

  Future<bool> startGateway() async {
    try {
      final result =
          await _channel.invokeMethod('startGateway');

      return result == true;

    } catch (_) {
      return false;
    }
  }

  Future<bool> stopGateway() async {
    try {
      final result =
          await _channel.invokeMethod('stopGateway');

      return result == true;

    } catch (_) {
      return false;
    }
  }
}
