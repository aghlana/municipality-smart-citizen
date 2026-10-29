
import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const ComplaintPage(),
    );
  }
}

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();

  String _category = 'النظافة';
  bool busy = false;

  final List<String> _categories = [
    'النظافة',
    'الطرق والأرصفة',
    'الإنارة العامة',
    'المياه والصرف الصحي',
    'الإشغالات والتعديات',
    'الحدائق والمرافق العامة',
    'أخرى',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      // تم التحقق من بيانات البلاغ.
      // يجب ربط هذا الموضع بخادم التطبيق لإرسال البلاغ فعليًا.
      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.teal,
              size: 42,
            ),
            title: const Text('البلاغ جاهز'),
            content: const Text(
              'تم التحقق من البيانات المدخلة، '
              'لكن إرسال البلاغ إلى البلدية يحتاج '
              'إلى ربط التطبيق بالخادم.',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('حسنًا'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validationMessage,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validationMessage;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بلدي - بلاغات المواطنين'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.location_city,
                    size: 72,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تقديم بلاغ جديد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يرجى إدخال المعلومات التالية',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _nameController,
                    label: 'اسم المواطن',
                    icon: Icons.person_outline,
                    validationMessage: 'يرجى إدخال الاسم',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_outlined,
                    validationMessage: 'يرجى إدخال رقم الهاتف',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _addressController,
                    label: 'عنوان موقع البلاغ',
                    icon: Icons.location_on_outlined,
                    validationMessage: 'يرجى إدخال عنوان الموقع',
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'نوع البلاغ',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _category = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _detailsController,
                    label: 'تفاصيل البلاغ',
                    icon: Icons.description_outlined,
                    validationMessage: 'يرجى كتابة تفاصيل البلاغ',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: busy ? null : send,
                    icon: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        busy
                            ? 'جارٍ إرسال البلاغ...'
                            : 'إرسال البلاغ',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'ملاحظة: يحتاج الإرسال الفعلي إلى ربط التطبيق '
                    'بخادم البلاغات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
