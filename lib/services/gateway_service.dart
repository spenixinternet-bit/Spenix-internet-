import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GatewayStatus {
  final bool online;
  final bool internetWorking;

  final double incomingMbps;
  final double usedMbps;

  final int onlineUsers;

  final String recommendation;

  final Map<String, double> userSpeeds;

  final String message;

  final String gatewayIp;
  final int wireguardPort;
  final int apiPort;

  GatewayStatus({
    required this.online,
    required this.internetWorking,
    required this.incomingMbps,
    required this.usedMbps,
    required this.onlineUsers,
    required this.recommendation,
    required this.userSpeeds,
    required this.message,
    this.gatewayIp = '',
    this.wireguardPort = 51820,
    this.apiPort = 8080,
  });

  factory GatewayStatus.waiting() {
    return GatewayStatus(
      online: false,
      internetWorking: false,
      incomingMbps: 0,
      usedMbps: 0,
      onlineUsers: 0,
      recommendation: 'WAITING FOR GATEWAY',
      userSpeeds: {},
      message: 'Gateway is waiting for connection.',
    );
  }

  factory GatewayStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSpeeds = json['userSpeeds'];

    final Map<String, double> speeds = {};

    if (rawSpeeds is Map) {
      rawSpeeds.forEach((key, value) {
        final speed = double.tryParse(
          value.toString(),
        );

        if (speed != null) {
          speeds[key.toString()] = speed;
        }
      });
    }

    return GatewayStatus(
      online: json['online'] == true,
      internetWorking:
          json['internetWorking'] == true,
      incomingMbps:
          double.tryParse(
                '${json['incomingMbps'] ?? 0}',
              ) ??
              0,
      usedMbps:
          double.tryParse(
                '${json['usedMbps'] ?? 0}',
              ) ??
              0,
      onlineUsers:
          int.tryParse(
                '${json['onlineUsers'] ?? 0}',
              ) ??
              0,
      recommendation:
          json['recommendation']?.toString() ??
              'WAIT',
      userSpeeds: speeds,
      message:
          json['message']?.toString() ??
              'Gateway data received.',
      gatewayIp:
          json['gatewayIp']?.toString() ?? '',
      wireguardPort:
          int.tryParse(
                '${json['wireguardPort'] ?? 51820}',
              ) ??
              51820,
      apiPort:
          int.tryParse(
                '${json['apiPort'] ?? 8080}',
              ) ??
              8080,
    );
  }
}

class GatewayService {
  static const String endpointKey =
      'gateway_api_url';

  static const String defaultEndpoint =
      'http://10.8.0.1:8080';

  static const Duration timeout =
      Duration(seconds: 5);

  static Future<String> getEndpoint() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getString(endpointKey);

    if (saved == null ||
        saved.trim().isEmpty) {
      return defaultEndpoint;
    }

    return saved.trim();
  }

  static Future<void> setEndpoint(
    String endpoint,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final value =
        endpoint.trim();

    if (value.isEmpty) {
      await prefs.remove(endpointKey);
      return;
    }

    await prefs.setString(
      endpointKey,
      value,
    );
  }

  static Future<void> clearEndpoint() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(endpointKey);
  }

  static Future<GatewayStatus> check() async {
    final endpoint =
        await getEndpoint();

    try {
      String url =
          endpoint.trim();

      while (url.endsWith('/')) {
        url = url.substring(
          0,
          url.length - 1,
        );
      }

      if (!url.endsWith('/status')) {
        url = '$url/status';
      }

      final response =
          await http
              .get(
                Uri.parse(url),
              )
              .timeout(timeout);

      if (response.statusCode != 200) {
        return GatewayStatus(
          online: false,
          internetWorking: false,
          incomingMbps: 0,
          usedMbps: 0,
          onlineUsers: 0,
          recommendation:
              'CHECK GATEWAY',
          userSpeeds: {},
          message:
              'Gateway returned HTTP ${response.statusCode}.',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        return GatewayStatus(
          online: false,
          internetWorking: false,
          incomingMbps: 0,
          usedMbps: 0,
          onlineUsers: 0,
          recommendation:
              'CHECK GATEWAY',
          userSpeeds: {},
          message:
              'Gateway returned invalid data.',
        );
      }

      return GatewayStatus.fromJson(
        Map<String, dynamic>.from(
          decoded,
        ),
      );
    } on TimeoutException {
      return GatewayStatus(
        online: false,
        internetWorking: false,
        incomingMbps: 0,
        usedMbps: 0,
        onlineUsers: 0,
        recommendation:
            'GATEWAY OFFLINE',
        userSpeeds: {},
        message:
            'The Spenix gateway did not respond.',
      );
    } catch (e) {
      return GatewayStatus(
        online: false,
        internetWorking: false,
        incomingMbps: 0,
        usedMbps: 0,
        onlineUsers: 0,
        recommendation:
            'CHECK CONNECTION',
        userSpeeds: {},
        message:
            'Unable to reach the Spenix gateway.',
      );
    }
  }
}
