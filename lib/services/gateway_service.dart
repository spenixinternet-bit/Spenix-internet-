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
    required this.gatewayIp,
    required this.wireguardPort,
    required this.apiPort,
  });

  factory GatewayStatus.waiting() {
    return GatewayStatus(
      online: false,
      internetWorking: false,
      incomingMbps: 0.0,
      usedMbps: 0.0,
      onlineUsers: 0,
      recommendation: 'WAIT',
      userSpeeds: <String, double>{},
      message: 'Waiting for Spenix gateway...',
      gatewayIp: '10.8.0.1',
      wireguardPort: 51820,
      apiPort: 8080,
    );
  }

  factory GatewayStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    final Map<String, double> speeds =
        <String, double>{};

    final dynamic rawSpeeds = json['userSpeeds'];

    if (rawSpeeds is Map) {
      rawSpeeds.forEach((key, value) {
        speeds[key.toString()] =
            double.tryParse(value.toString()) ?? 0.0;
      });
    }

    return GatewayStatus(
      online: json['online'] == true,
      internetWorking:
          json['internetWorking'] == true,
      incomingMbps:
          double.tryParse(
                json['incomingMbps']?.toString() ?? '0',
              ) ??
              0.0,
      usedMbps:
          double.tryParse(
                json['usedMbps']?.toString() ?? '0',
              ) ??
              0.0,
      onlineUsers:
          int.tryParse(
                json['onlineUsers']?.toString() ?? '0',
              ) ??
              0,
      recommendation:
          json['recommendation']?.toString() ?? 'WAIT',
      userSpeeds: speeds,
      message:
          json['message']?.toString() ??
              'No gateway message.',
      gatewayIp:
          json['gatewayIp']?.toString() ?? '10.8.0.1',
      wireguardPort:
          int.tryParse(
                json['wireguardPort']?.toString() ?? '51820',
              ) ??
              51820,
      apiPort:
          int.tryParse(
                json['apiPort']?.toString() ?? '8080',
              ) ??
              8080,
    );
  }
}

class GatewayService {
  static const String _endpointKey = 'gateway_api_url';

  static const String defaultEndpoint =
      'http://10.8.0.1:8080';

  static Future<String> getEndpoint() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? saved =
        prefs.getString(_endpointKey);

    if (saved == null || saved.trim().isEmpty) {
      return defaultEndpoint;
    }

    return saved.trim();
  }

  static Future<void> setEndpoint(
    String endpoint,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String value = endpoint.trim();

    if (value.isEmpty) {
      await prefs.remove(_endpointKey);
    } else {
      await prefs.setString(
        _endpointKey,
        value,
      );
    }
  }

  static Future<GatewayStatus> check() async {
    try {
      String endpoint = await getEndpoint();

      endpoint = endpoint.replaceFirst(
        RegExp(r'/$'),
        '',
      );

      final Uri url = Uri.parse(
        '$endpoint/status',
      );

      final http.Response response =
          await http.get(
        url,
        headers: <String, String>{
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) {
        return GatewayStatus(
          online: false,
          internetWorking: false,
          incomingMbps: 0.0,
          usedMbps: 0.0,
          onlineUsers: 0,
          recommendation: 'WAIT',
          userSpeeds: <String, double>{},
          message:
              'Gateway API error: HTTP ${response.statusCode}',
          gatewayIp: '10.8.0.1',
          wireguardPort: 51820,
          apiPort: 8080,
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        return GatewayStatus(
          online: false,
          internetWorking: false,
          incomingMbps: 0.0,
          usedMbps: 0.0,
          onlineUsers: 0,
          recommendation: 'WAIT',
          userSpeeds: <String, double>{},
          message:
              'Gateway returned invalid status data.',
          gatewayIp: '10.8.0.1',
          wireguardPort: 51820,
          apiPort: 8080,
        );
      }

      return GatewayStatus.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      return GatewayStatus(
        online: false,
        internetWorking: false,
        incomingMbps: 0.0,
        usedMbps: 0.0,
        onlineUsers: 0,
        recommendation: 'WAIT',
        userSpeeds: <String, double>{},
        message:
            'Gateway cannot be reached through the VPN.',
        gatewayIp: '10.8.0.1',
        wireguardPort: 51820,
        apiPort: 8080,
      );
    }
  }
}
