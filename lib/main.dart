
import 'package:flutter/material.dart';
import 'services/api.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  runApp(const MunicipalityApp());
}

class MunicipalityApp extends StatelessWidget {
  const MunicipalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بلدي - خدمات المواطنين',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool staff = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      message('أدخل اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() => busy = true);

    try {
      final result = staff
          ? await Api.staffLogin(
              username.text.trim(),
              password.text,
            )
          : await Api.login(
              username.text.trim(),
              password.text,
            );

      if (!mounted) return;

      final role = result['role'] ?? 'citizen';

      if (role == 'manager') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ManagerPage(),
          ),
        );
      } else if (role == 'employee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmployeePage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CitizenPage(),
          ),
        );
      }
    } catch (e) {
      message('تعذر تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بلدي - تسجيل الدخول')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.location_city,
                  size: 85,
                  color: Colors.teal,
                ),
                const SizedBox(height: 20),
                const Text(
                  'بلدية المواطن الذكي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('مواطن'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('موظف / مدير'),
                      icon: Icon(Icons.badge),
                    ),
                  ],
                  selected: {staff},
                  onSelectionChanged: (value) {
                    setState(() => staff = value.first);
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: username,
                  decoration: InputDecoration(
                    labelText: staff
                        ? 'اسم المستخدم'
                        : 'رقم الهاتف',
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 25),
                FilledButton(
                  onPressed: busy ? null : login,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: busy
                        ? const CircularProgressIndicator()
                        : const Text('دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CitizenPage extends StatelessWidget {
  const CitizenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('خدمات المواطنين')),
        body: CitizenHome(),
      ),
    );
  }
}

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  final title = TextEditingController();
  final details = TextEditingController();
  bool busy = false;

  Future<void> sendReport() async {
    if (title.text.trim().isEmpty ||
        details.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل عنوان البلاغ والتفاصيل'),
        ),
      );
      return;
    }

    setState(() => busy = true);

    try {
      await Api.createReport(
        title: title.text.trim(),
        description: details.text.trim(),
        category: '',
      );

      title.clear();
      details.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال البلاغ بنجاح'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال البلاغ: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Icon(
            Icons.location_city,
            size: 70,
            color: Colors.teal,
          ),
          const Text(
            'تقديم بلاغ جديد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: title,
            decoration: const InputDecoration(
              labelText: 'عنوان البلاغ',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: details,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'تفاصيل البلاغ',
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : sendReport,
            icon: const Icon(Icons.send),
            label: Text(
              busy ? 'جارٍ الإرسال...' : 'إرسال البلاغ',
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                final reports = await Api.reports();

                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('بلاغاتي'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: reports.isEmpty
                          ? const Text('لا توجد بلاغات')
                          : ListView(
                              shrinkWrap: true,
                              children: reports.map((r) {
                                return ListTile(
                                  title: Text(
                                    r['title']?.toString() ?? '',
                                  ),
                                  subtitle: Text(
                                    r['status']?.toString() ?? '',
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            },
            icon: const Icon(Icons.list),
            label: const Text('متابعة بلاغاتي'),
          ),
        ],
      ),
    );
  }
}

class ManagerPage extends StatelessWidget {
  const ManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة المدير')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('مرحباً بك في لوحة المدير'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('إدارة الموظفين'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployeesPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('بلاغات المواطنين'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagerReportsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                await Api.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بوابة الموظف')),
        body: const Center(
          child: Text('مرحباً بك في بوابة الموظف'),
        ),
      ),
    );
  }
}

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = Api.employees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الموظفين')),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('خطأ: ${snapshot.error}'),
            );
          }

          final employees = snapshot.data ?? [];

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];

              return ListTile(
                title: Text(
                  employee['full_name']?.toString() ?? '',
                ),
                subtitle: Text(
                  employee['department']?.toString() ?? '',
                ),
                trailing: Text(
                  employee['active'] == 1 ? 'نشط' : 'معطل',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ManagerReportsPage extends StatelessWidget {
  const ManagerReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بلاغات المواطنين')),
      body: FutureBuilder<List<dynamic>>(
        future: Api.managerReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('خطأ: ${snapshot.error}'),
            );
          }

          final reports = snapshot.data ?? [];

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              return ListTile(
                title: Text(
                  report['title']?.toString() ?? '',
                ),
                subtitle: Text(
                  '${report['full_name'] ?? ''} - '
                  '${report['status'] ?? ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
