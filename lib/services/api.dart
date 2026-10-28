import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class Api {
  static Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString('token');

  static Future<Map<String, dynamic>> request(
    String method, String path, {Map<String, dynamic>? body, bool auth = false}
  ) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    late http.Response response;
    if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 20));
    } else {
      response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    }
    final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'تعذر الاتصال بالخادم');
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(String email, String password) =>
      request('POST', '/auth/login', body: {'email': email, 'password': password});

  static Future<Map<String, dynamic>> register(String name, String email, String phone, String password) =>
      request('POST', '/auth/register', body: {'name': name, 'email': email, 'phone': phone, 'password': password});

  static Future<List<dynamic>> reports() async =>
      (await request('GET', '/reports', auth: true))['reports'] as List<dynamic>;

  static Future<void> createReport({
    required String title, required String description, required String category,
    double? latitude, double? longitude, File? image,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/reports');
    final req = http.MultipartRequest('POST', uri);
    final t = await token;
    if (t != null) req.headers['Authorization'] = 'Bearer $t';
    req.fields.addAll({
      'title': title, 'description': description, 'category': category,
      if (latitude != null) 'latitude': '$latitude',
      if (longitude != null) 'longitude': '$longitude',
    });
    if (image != null) req.files.add(await http.MultipartFile.fromPath('image', image.path));
    final streamed = await req.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);
    final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'فشل إرسال البلاغ');
    }
  }
}
