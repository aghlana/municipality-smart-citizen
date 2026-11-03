
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class Api {
  static Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString('token');

  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    // تحديث عنوان السيرفر قبل الاتصال
    await ApiConfig.initialize();

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final t = await token;
      if (t != null) {
        headers['Authorization'] = 'Bearer $t';
      }
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    late http.Response response;

    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ).timeout(const Duration(seconds: 20));
    } else if (method == 'PATCH') {
      response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ).timeout(const Duration(seconds: 20));
    } else {
      response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 20));
    }

    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'تعذر الاتصال بالخادم');
    }

    return data;
  }

  static Future<void> saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // تسجيل دخول المواطن برقم الهاتف
  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    return request(
      'POST',
      '/login',
      body: {
        'phone': phone,
        'password': password,
      },
    );
  }

  // تسجيل دخول الموظف والمدير
  static Future<Map<String, dynamic>> staffLogin(
    String username,
    String password,
  ) async {
    return request(
      'POST',
      '/staff/login',
      body: {
        'username': username,
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return request(
      'POST',
      '/register',
      body: {
        'full_name': name,
        'phone': phone,
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> me() =>
      request('GET', '/me', auth: true);

  static Future<List<dynamic>> departments() async =>
      (await request('GET', '/departments'))['departments'] ?? [];

  static Future<List<dynamic>> services() async =>
      (await request('GET', '/services'))['services'] ?? [];

  static Future<List<dynamic>> reports() async =>
      (await request('GET', '/reports', auth: true))['reports'] ?? [];

  static Future<void> createReport({
    required String title,
    required String description,
    required String category,
    double? latitude,
    double? longitude,
  }) async {
    await request(
      'POST',
      '/reports',
      auth: true,
      body: {
        'title': title,
        'description': description,
        'category': category,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  static Future<List<dynamic>> managerReports() async =>
      (await request('GET', '/manager/reports', auth: true))['reports'] ?? [];

  static Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> employee,
  ) =>
      request(
        'POST',
        '/manager/employees',
        auth: true,
        body: employee,
      );

  static Future<List<dynamic>> employees() async =>
      (await request('GET', '/manager/employees', auth: true))['employees'] ?? [];

  static Future<Map<String, dynamic>> setEmployeeStatus(
    int id,
    String status,
  ) =>
      request(
        'PATCH',
        '/manager/employees/$id/status',
        auth: true,
        body: {'status': status},
      );
}
