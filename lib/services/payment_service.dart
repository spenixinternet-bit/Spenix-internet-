import 'dart:convert';
import 'package:http/http.dart' as http;

class GosentePayService {
  // ✅ OFFLINE MODE – Users buy with 0MB data
  static const bool offlineMode = true;

  // These are only used if offlineMode = false
  static const String apiKey = 'YOUR_API_KEY';
  static const String apiSecret = 'YOUR_SECRET';
  static const String baseUrl = 'https://eos2pf4txrsyyi9.m.pipedream.net';

  static Future<Map<String, dynamic>> initiatePayment({
    required String phone,
    required double amount,
    required String userId,
    required String packageId,
    required String packageName,
  }) async {
    // ============================================================
    // OFFLINE MODE – 0MB DATA USAGE
    // The user buys the package locally without internet
    // ============================================================
    if (offlineMode) {
      await Future.delayed(const Duration(seconds: 1));

      // Generate VPN credentials for the user
      final vpnUsername = userId;
      final vpnPassword = 'VPN${DateTime.now().millisecondsSinceEpoch}';

      return {
        'success': true,
        'reference': 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
        'message': '✅ Package purchased successfully!',
        'offline': true,
        'vpnCredentials': {
          'server': 'YOUR_GATEWAY_IP', // 👈 CHANGE THIS TO YOUR GATEWAY IP
          'username': vpnUsername,
          'password': vpnPassword,
        },
      };
    }

    // ============================================================
    // ONLINE MODE – Real payment (uses mobile data)
    // ============================================================
    final url = Uri.parse(baseUrl);
    final reference = 'SPX${DateTime.now().millisecondsSinceEpoch}';

    final body = {
      'phone': phone,
      'amount': amount.toString(),
      'currency': 'UGX',
      'reference': reference,
      'metadata': {
        'userId': userId,
        'packageId': packageId,
        'packageName': packageName,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'reference': data['data']['reference'] ?? reference,
          'status': data['data']['status'] ?? 'pending',
          'message': data['message'] ?? 'Payment initiated',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'API error',
          'reference': reference,
          'status': 'failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'reference': '',
        'status': 'failed',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    // ============================================================
    // OFFLINE MODE – Skip verification (0MB data)
    // ============================================================
    if (offlineMode) {
      return {
        'success': true,
        'status': 'success',
        'reference': reference,
        'message': '✅ Subscription activated!',
        'offline': true,
      };
    }

    // ============================================================
    // ONLINE MODE – Real verification (uses data)
    // ============================================================
    final url = Uri.parse('$baseUrl/payment/verify/$reference');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': data['data']['status'] ?? 'pending',
          'reference': reference,
          'message': data['message'] ?? 'Verification successful',
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'reference': reference,
          'message': data['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'reference': reference,
        'message': 'Network error: $e',
      };
    }
  }
}
