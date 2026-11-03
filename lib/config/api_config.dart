
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String configUrl =
      'https://raw.githubusercontent.com/aghlana/municipality-smart-citizen/main/server_config.json';

  static const String defaultUrl =
      'https://checkout-prepared-sending-let.trycloudflare.com/api';

  static String baseUrl = defaultUrl;

  static bool _initialized = false;

  static Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;

    final prefs = await SharedPreferences.getInstance();

    // استخدام الرابط الجديد مباشرة
    baseUrl = defaultUrl;

    try {
      final response = await http
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newUrl = data['baseUrl'];

        if (newUrl is String &&
            newUrl.startsWith('https://') &&
            newUrl.endsWith('/api')) {
          baseUrl = newUrl;
        }
      }
    } catch (_) {
      // الاحتفاظ بالرابط الافتراضي الجديد
    }

    // حفظ الرابط الجديد بدلاً من القديم
    await prefs.setString('server_base_url', baseUrl);

    _initialized = true;
  }
}
