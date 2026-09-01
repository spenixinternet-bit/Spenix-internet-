import 'dart:convert';
import 'package:http/http.dart' as http;

class GosentePayService {
  // Your credentials
  static const String apiKey = '9d6c7d3c450aa51ca4c100fbe0adf5c1145c3a1e5eb665e1f4fac61a29e5c070';
  static const String apiSecret = '99F899BE-4D93F38E-2E1717C9-D07CDD5F-73C3E4CB-EB6B3187';
  
  // ✅ UPDATED: Your GosentePay API base URL
  static const String baseUrl = 'https://ais-pre-22chskp4ocozqv4i7hb7rc-697152507609.europe-west2.run.app/api';
  
  // Your callback URL (for GosentePay to notify you)
  static const String callbackUrl = 'https://ais-pre-22chskp4ocozqv4i7hb7rc-697152507609.europe-west2.run.app/api/payment/callback';

  static Future<Map<String, dynamic>> initiatePayment({
    required String phone,
    required double amount,
    required String userId,
    required String packageId,
    required String packageName,
  }) async {
    final url = Uri.parse('$baseUrl/payment/initiate');
    final reference = 'SPX${DateTime.now().millisecondsSinceEpoch}';

    final body = {
      'phone': phone,
      'amount': amount.toString(),
      'currency': 'UGX',
      'reference': reference,
      'callback': callbackUrl, // 👈 Sends callback URL to GosentePay
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
