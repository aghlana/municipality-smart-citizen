
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'services/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  runApp(const MunicipalityApp());
}

const Color navy = Color(0xFF153B50);
const Color teal = Color(0xFF168C83);

class MunicipalityApp extends StatelessWidget {
  const MunicipalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'المواطن الذكي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const LoginPage(),
    );
  }
}

// تسجيل الدخول

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  bool isStaff = false;
  bool busy = false;
  String? error;

  Future<void> login() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final result = isStaff
          ? await Api.staffLogin(
              usernameController.text.trim(),
              passwordController.text,
            )
          : await Api.login(
              phoneController.text.trim(),
              passwordController.text,
            );

      final token = result['token'];
      if (token == null) {
        throw Exception('لم يرجع الخادم رمز تسجيل الدخول');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token.toString());

      final role = (result['role'] ?? 'citizen').toString().toLowerCase();

      if (!mounted) return;

      Widget page;
      if (role == 'manager' || role == 'admin') {
        page = const ManagerPage();
      } else if (isStaff || role == 'employee') {
        page = const EmployeePage();
      } else {
        page = const CitizenPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.location_city, size: 75, color: teal),
                const SizedBox(height: 15),
                const Text(
                  'المواطن الذكي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'بوابة الخدمات البلدية الإلكترونية',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
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
                  selected: {isStaff},
                  onSelectionChanged: (value) {
                    setState(() {
                      isStaff = value.first;
                      error = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (isStaff)
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: busy ? null : login,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Text(
                      busy ? 'جارٍ تسجيل الدخول...' : 'دخول',
                    ),
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

// صفحة المواطن

class CitizenPage extends StatelessWidget {
  const CitizenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خدمات المواطنين'),
          actions: [
            IconButton(
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: const CitizenHome(),
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
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: selectedTab == 0
              ? const CitizenDashboard()
              : const ReportsPage(),
        ),
        NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (value) {
            setState(() => selectedTab = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'بلاغاتي',
            ),
          ],
        ),
      ],
    );
  }
}

class CitizenDashboard extends StatelessWidget {
  const CitizenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_city, color: Colors.white, size: 45),
              SizedBox(height: 12),
              Text(
                'مرحباً بك في بلديتك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'يمكنك تقديم البلاغات ومتابعة الخدمات البلدية.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'الخدمات المتاحة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const ServiceTile(icon: Icons.home_work, title: 'خدمات العقارات'),
        const ServiceTile(icon: Icons.water_drop, title: 'عدادات المياه'),
        const ServiceTile(icon: Icons.electric_bolt, title: 'عدادات الكهرباء'),
        const ServiceTile(
          icon: Icons.cleaning_services,
          title: 'النظافة والصرف الصحي',
        ),
        const ServiceTile(icon: Icons.event, title: 'حجز صالة الأفراح'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewReportPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('تقديم بلاغ جديد'),
        ),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const ServiceTile({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: teal.withValues(alpha: 0.12),
          child: Icon(icon, color: teal),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

// تقديم بلاغ

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  @override
  State<NewReportPage> createState() => _NewReportPageState();
}

class _NewReportPageState extends State<NewReportPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = 'النظافة';
  bool busy = false;
  String? error;

  final categories = const [
    'النظافة',
    'الطرق والحفر',
    'إنارة الطرق',
    'الصرف الصحي',
    'مخالفات البناء',
    'أخرى',
  ];

  Future<void> sendReport() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      setState(() => error = 'يرجى إدخال عنوان البلاغ والوصف');
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await Api.createReport(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: category,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقديم بلاغ جديد')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان البلاغ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(
              labelText: 'نوع البلاغ',
              border: OutlineInputBorder(),
            ),
            items: categories.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => category = value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'تفاصيل البلاغ',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : sendReport,
            icon: const Icon(Icons.send),
            label: Text(busy ? 'جارٍ إرسال البلاغ...' : 'إرسال البلاغ'),
          ),
        ],
      ),
    );
  }
}

// عرض بلاغات المواطن

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<List<dynamic>> reportsFuture;

  @override
  void initState() {
    super.initState();
    reportsFuture = Api.reports();
  }

  Future<void> refresh() async {
    setState(() => reportsFuture = Api.reports());
    await reportsFuture;
  }

  String statusName(dynamic status) {
    switch (status) {
      case 'received':
        return 'تم الاستلام';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'completed':
        return 'تم التنفيذ';
      case 'rejected':
        return 'مرفوض';
      default:
        return status?.toString() ?? 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تعذر تحميل البلاغات'),
                TextButton(
                  onPressed: refresh,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(child: Text('لا توجد بلاغات حتى الآن'));
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index] as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: teal),
                  title: Text('${report['title'] ?? ''}'),
                  subtitle: Text(
                    '${report['description'] ?? ''}\n'
                    'الحالة: ${statusName(report['status'])}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// صفحة المدير

class ManagerPage extends StatelessWidget {
  const ManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'إدارة البلدية',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment, color: teal),
              title: const Text('بلاغات المواطنين'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagerReportsPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: teal),
              title: const Text('الموظفون'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeesPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// صفحة الموظف

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الموظف'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'مرحباً بك في بوابة موظفي البلدية',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

// قائمة الموظفين

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
      appBar: AppBar(title: const Text('الموظفون')),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return const Center(child: Text('لا يوجد موظفون مسجلون'));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index] as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    '${employee['full_name'] ?? employee['username'] ?? ''}',
                  ),
                  subtitle: Text(
                    '${employee['department'] ?? employee['role'] ?? ''}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// بلاغات المدير

class ManagerReportsPage extends StatefulWidget {
  const ManagerReportsPage({super.key});

  @override
  State<ManagerReportsPage> createState() => _ManagerReportsPageState();
}

class _ManagerReportsPageState extends State<ManagerReportsPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = Api.managerReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بلاغات المواطنين')),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(child: Text('لا توجد بلاغات'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index] as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.report_problem, color: teal),
                  title: Text('${report['title'] ?? ''}'),
                  subtitle: Text(
                    '${report['description'] ?? ''}\n'
                    'الحالة: ${report['status'] ?? 'غير محدد'}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// تسجيل الخروج

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
