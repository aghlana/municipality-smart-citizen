
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class Api {
  static Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // تنفيذ طلبات الاتصال بالسيرفر
  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
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
      response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 25));
    } else if (method == 'PATCH') {
      response = await http
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 25));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 25));
    }

    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['message'] ??
            data['error'] ??
            'تعذر الاتصال بالخادم',
      );
    }

    return data;
  }

  // حفظ رمز الدخول
  static Future<void> saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', value);
  }

  // تسجيل خروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // تسجيل دخول المواطن برقم الهاتف
  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final result = await request(
      'POST',
      '/login',
      body: {
        'phone': phone,
        'password': password,
      },
    );

    if (result['token'] != null) {
      await saveToken(result['token']);
    }

    return result;
  }

  // تسجيل دخول الموظف أو المدير
  static Future<Map<String, dynamic>> staffLogin(
    String username,
    String password,
  ) async {
    final result = await request(
      'POST',
      '/staff/login',
      body: {
        'username': username,
        'password': password,
      },
    );

    if (result['token'] != null) {
      await saveToken(result['token']);
    }

    return result;
  }

  // تسجيل مواطن جديد
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final result = await request(
      'POST',
      '/register',
      body: {
        'full_name': name,
        'phone': phone,
        'password': password,
      },
    );

    return result;
  }

  // جلب بيانات المستخدم الحالي
  static Future<Map<String, dynamic>> me() {
    return request('GET', '/me', auth: true);
  }

  // جلب الأقسام
  static Future<List<dynamic>> departments() async {
    final result = await request('GET', '/departments');
    return result['departments'] as List<dynamic>;
  }

  // جلب الخدمات
  static Future<List<dynamic>> services() async {
    final result = await request('GET', '/services');
    return result['services'] as List<dynamic>;
  }

  // جلب بلاغات المواطن
  static Future<List<dynamic>> reports() async {
    final result = await request(
      'GET',
      '/reports',
      auth: true,
    );

    return result['reports'] as List<dynamic>;
  }

  // إرسال بلاغ جديد
  static Future<void> createReport({
    required String title,
    required String description,
    required String category,
    double? latitude,
    double? longitude,
    File? image,
  }) async {
    await ApiConfig.initialize();

    final uri = Uri.parse('${ApiConfig.baseUrl}/reports');

    final req = http.MultipartRequest('POST', uri);

    final t = await token;

    if (t != null) {
      req.headers['Authorization'] = 'Bearer $t';
    }

    req.fields.addAll({
      'title': title,
      'description': description,
      if (category.isNotEmpty) 'category': category,
      if (latitude != null) 'latitude': '$latitude',
      if (longitude != null) 'longitude': '$longitude',
    });

    if (image != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
        ),
      );
    }

    final streamed = await req
        .send()
        .timeout(const Duration(seconds: 45));

    final response = await http.Response.fromStream(streamed);

    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['message'] ??
            data['error'] ??
            'فشل إرسال البلاغ',
      );
    }
  }

  // عرض بلاغات جميع المواطنين للمدير
  static Future<List<dynamic>> managerReports() async {
    final result = await request(
      'GET',
      '/manager/reports',
      auth: true,
    );

    return result['reports'] as List<dynamic>;
  }

  // إنشاء حساب موظف
  static Future<Map<String, dynamic>> createEmployee({
    required String fullName,
    required String username,
    required String password,
    required String department,
    List<String> permissions = const [],
  }) {
    return request(
      'POST',
      '/manager/employees',
      auth: true,
      body: {
        'full_name': fullName,
        'username': username,
        'password': password,
        'department': department,
        'permissions': permissions,
      },
    );
  }

  // عرض الموظفين
  static Future<List<dynamic>> employees() async {
    final result = await request(
      'GET',
      '/manager/employees',
      auth: true,
    );

    return result['employees'] as List<dynamic>;
  }

  // تفعيل أو تعطيل حساب موظف
  static Future<Map<String, dynamic>> setEmployeeStatus(
    int id,
    bool active,
  ) {
    return request(
      'PATCH',
      '/manager/employees/$id/status',
      auth: true,
      body: {
        'active': active ? 1 : 0,
      },
    );
  }
}
