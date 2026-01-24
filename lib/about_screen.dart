
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), // Max width for larger text content
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Make card wrap content
                children: [
                  Center(
                    child: Text(
                      'تطبيق إدارة شؤون الموظفين',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تم تطوير هذا التطبيق لإدارة العلاوات والترفيعات للموظفين بناءً على أحكام قانون رواتب موظفي الدولة والقطاع العام رقم 22 لسنة 2008 في العراق.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'الميزات الرئيسية:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text('• حساب تلقائي للعلاوات السنوية.'),
                  const Text('• تتبع مواعيد استحقاق الترفيعات.'),
                  const Text('• إدارة بيانات الموظفين (إضافة, تعديل, حذف).'),
                  const Text('• واجهة متجاوبة مع جميع أحجام الشاشات.'),
                  const Spacer(), // Pushes the version to the bottom
                  const Center(
                    child: Text(
                      'الإصدار 1.1.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
