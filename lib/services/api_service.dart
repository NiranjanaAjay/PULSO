import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> analyzeSession(String readingId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('User not authenticated');
    }

    final token = session.accessToken;
    print('DEBUG: Sending token to backend: ${token.substring(0, 50)}...');
    final url = Uri.parse(
      '${BackendConfig.apiUrl}/analysis/request/$readingId',
    );

    final client = HttpClient();

    try {
      // Allow self-signed certs if we were using HTTPS (not needed for http, but good practice for local dev sometimes)
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

      final request = await client.postUrl(url);

      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      // Empty body as the backend pulls data from DB based on ID
      request.write(jsonEncode({}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Analysis failed: ${response.statusCode} - $responseBody',
        );
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getAnalysis(String readingId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final token = session.accessToken;
    final url = Uri.parse('${BackendConfig.apiUrl}/analysis/$readingId');
    final client = HttpClient();

    try {
      client.badCertificateCallback = ((cert, host, port) => true);
      final request = await client.getUrl(url);
      request.headers.set('Authorization', 'Bearer $token');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? sessionId,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final token = session.accessToken;
    final url = Uri.parse('${BackendConfig.apiUrl}/chat/message');
    final client = HttpClient();

    try {
      client.badCertificateCallback = ((cert, host, port) => true);
      final request = await client.postUrl(url);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      final body = {'message': message};
      if (sessionId != null) {
        body['session_id'] = sessionId;
      }
      request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception('Chat failed: ${response.statusCode} - $responseBody');
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getChatHistory({int limit = 10}) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final token = session.accessToken;
    final url = Uri.parse('${BackendConfig.apiUrl}/chat/history?limit=$limit');
    final client = HttpClient();

    try {
      client.badCertificateCallback = ((cert, host, port) => true);
      final request = await client.getUrl(url);
      request.headers.set('Authorization', 'Bearer $token');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get chat history: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
}
