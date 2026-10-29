import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api.dart';

void main() => runApp(const MunicipalityApp());

const navy = Color(0xFF153B50);
const teal = Color(0xFF168C83);

class MunicipalityApp extends StatelessWidget {
  const MunicipalityApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'بلدي',
    theme: ThemeData(
      useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: teal),
      scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const GatePage(),
  );
}

class GatePage extends StatefulWidget {
  const GatePage({super.key});
  @override State<GatePage> createState() => _GatePageState();
}
class _GatePageState extends State<GatePage> {
  bool? loggedIn;
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => loggedIn = p.getString('token') != null);
  }
  @override Widget build(BuildContext context) {
    if (loggedIn == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return loggedIn! ? HomePage(onLogout: () => setState(() => loggedIn = false))
      : AuthPage(onLogin: () => setState(() => loggedIn = true));
  }
}

class AuthPage extends StatefulWidget {
  final VoidCallback onLogin;
  const AuthPage({super.key, required this.onLogin});
  @override State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController(), phone = TextEditingController();
  bool register = false, busy = false;
  String? error;
  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      final result = register
        ? await Api.register(name.text.trim(), email.text.trim(), phone.text.trim(), password.text)
        : await Api.login(email.text.trim(), password.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token'] as String);
      widget.onLogin();
    } catch (e) { setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override void dispose() { email.dispose(); password.dispose(); name.dispose(); phone.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.location_city, size: 76, color: teal),
        const SizedBox(height: 12),
        const Text('بلدي', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: navy)),
        const Text('خدمات البلدية بين يديك', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        Text(register ? 'إنشاء حساب مواطن' : 'تسجيل الدخول', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (register) ...[
          const SizedBox(height: 12), TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
          const SizedBox(height: 12), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)')),
        ],
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 20),
        FilledButton(onPressed: busy ? null : submit, child: Padding(padding: const EdgeInsets.all(12), child: Text(busy ? 'يرجى الانتظار...' : register ? 'إنشاء الحساب' : 'دخول'))),
        TextButton(onPressed: busy ? null : () => setState(() { register = !register; error = null; }), child: Text(register ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ حسابًا')),
        const SizedBox(height: 8),
        const Text('نسخة أولية: استخدم بريدًا إلكترونيًا وكلمة مرور تجريبية.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    )))),
  );
}

class HomePage extends StatefulWidget {
  final VoidCallback onLogout;
  const HomePage({super.key, required this.onLogout});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('بلدي | خدمات البلدية'), actions: [
      IconButton(tooltip: 'تسجيل الخروج', onPressed: () async {
        final p = await SharedPreferences.getInstance(); await p.remove('token'); widget.onLogout();
      }, icon: const Icon(Icons.logout)),
    ]),
    body: IndexedStack(index: tab, children: [const DashboardPage(), const ReportsPage()]),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
      NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'بلاغاتي'),
    ]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () async {
      final sent = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const NewReportPage()));
      if (sent == true && mounted) setState(() => tab = 1);
    }, icon: const Icon(Icons.add), label: const Text('تقديم بلاغ')),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, teal]), borderRadius: BorderRadius.circular(22)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.location_city, color: Colors.white, size: 42), SizedBox(height: 12),
      Text('مرحبًا بك في بلدي', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      SizedBox(height: 8), Text('ساهم في تحسين مدينتك. أرسل بلاغًا وتابع حالته من مكان واحد.', style: TextStyle(color: Colors.white, height: 1.6)),
    ]),
    const SizedBox(height: 22), const Text('الخدمات السريعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    const Row(children: [
      Expanded(child: ServiceTile(icon: Icons.delete_outline, title: 'النظافة', color: teal)),
      SizedBox(width: 10), Expanded(child: ServiceTile(icon: Icons.lightbulb_outline, title: 'إنارة الطرق', color: Colors.orange)),
    ]),
    const SizedBox(height: 10), const Row(children: [
      Expanded(child: ServiceTile(icon: Icons.construction, title: 'الطرق والحفر', color: Colors.deepOrange)),
      SizedBox(width: 10), Expanded(child: ServiceTile(icon: Icons.apartment, title: 'مخالفات البناء', color: navy)),
    ]),
    const SizedBox(height: 22),
    const Card(child: ListTile(leading: Icon(Icons.info_outline, color: teal), title: Text('مركز الخدمات'), subtitle: Text('يمكنك إرسال البلاغات ومتابعة حالتها من قسم «بلاغاتي».'))),
  ]);
}
class ServiceTile extends StatelessWidget {
  final IconData icon; final String title; final Color color;
  const ServiceTile({super.key, required this.icon, required this.title, required this.color});
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8), child: Column(children: [
    CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
    const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
  ])));
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override State<ReportsPage> createState() => _ReportsPageState();
}
class _ReportsPageState extends State<ReportsPage> {
  late Future<List<dynamic>> future;
  @override void initState() { super.initState(); future = Api.reports(); }
  String statusName(dynamic s) => switch (s) {
    'received' => 'تم الاستلام', 'in_progress' => 'قيد المعالجة', 'completed' => 'تم التنفيذ', 'rejected' => 'مرفوض', _ => '$s'
  };
  @override Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: future, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 12), Text('${snapshot.error}', textAlign: TextAlign.center),
        TextButton(onPressed: () => setState(() => future = Api.reports()), child: const Text('إعادة المحاولة')),
      ])));
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.assignment_outlined, size: 60, color: teal), SizedBox(height: 12), Text('لا توجد بلاغات حتى الآن')]));
      return RefreshIndicator(onRefresh: () async => setState(() => future = Api.reports()), child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (context, i) {
        final r = items[i] as Map<String, dynamic>;
        return Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.report_problem_outlined)),
          title: Text('${r['title'] ?? ''}'), subtitle: Text('${r['category'] ?? ''}\n${r['description'] ?? ''}'),
          isThreeLine: true, trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: teal.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Text(statusName(r['status']), style: const TextStyle(fontSize: 11, color: navy))),
        ));
      }));
    });
}

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});
  @override State<NewReportPage> createState() => _NewReportPageState();
}
class _NewReportPageState extends State<NewReportPage> {
  final title = TextEditingController(), description = TextEditingController();
  final categories = const ['حفرة في الطريق', 'تراكم نفايات', 'عطل إنارة', 'مخالفة بناء', 'أخرى'];
  String category = 'حفرة في الطريق';
  File? image; Position? position; bool busy = false; String? error;
  Future<void> locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('يرجى السماح بالوصول إلى الموقع أو إرسال البلاغ دون موقع');
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('فعّل خدمة الموقع GPS');
      final p = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => position = p);
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
  }
  Future<void> pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1600);
    if (x != null && mounted) setState(() => image = File(x.path));
  }
  Future<void> send() async {
    if (title.text.trim().isEmpty || description.text.trim().isEmpty) { setState(() => error = 'أدخل عنوان البلاغ ووصفه'); return; }
    setState(() { busy = true; error = null; });
    try {
      await Api.createReport(title: title.text.trim(), description: description.text.trim(), category: category, latitude: position?.latitude, longitude: position?.longitude, image: image);
      if (mounted) Navigator.pop(context, true);
    } catch (e) { setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override void dispose() { title.dispose(); description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تقديم بلاغ جديد')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('ساعدنا على تحسين مدينتك بإرسال تفاصيل واضحة عن المشكلة.', style: TextStyle(height: 1.6)),        ])),
      const SizedBox(height: 18), TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان البلاغ', hintText: 'مثال: حفرة أمام المنزل')),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'نوع المشكلة'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) setState(() => category = v); }),
      const SizedBox(height: 12), TextField(controller: description, maxLines: 5, decoration: const InputDecoration(labelText: 'وصف المشكلة', alignLabelWithHint: true, hintText: 'اذكر التفاصيل وأقرب معلم معروف')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: locate, icon: const Icon(Icons.my_location), label: Text(position == null ? 'تحديد موقعي عبر GPS' : 'تم تحديد الموقع: ${position!.latitude.toStringAsFixed(4)}, ${position!.longitude.toStringAsFixed(4)}')),
      OutlinedButton.icon(onPressed: pickImage, icon: const Icon(Icons.camera_alt_outlined), label: Text(image == null ? 'التقاط صورة للمشكلة (اختياري)' : 'تم إرفاق صورة')),
      if (image != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image!, height: 180, fit: BoxFit.cover))),
      if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 12), FilledButton.icon(onPressed: busy ? null : send, icon: const Icon(Icons.send), label: Padding(padding: const EdgeInsets.all(12), child: Text(busy ? 'جارٍ إرسال البلاغ...' : 'إرسال البلاغ'))),
    ]),
  );
}


