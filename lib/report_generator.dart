
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/grade_model.dart';
import 'package:myapp/notifications_provider.dart';
import 'package:myapp/thanks_book_model.dart';
import 'package:provider/provider.dart';

class ReportGenerator {
  static String _formatThanksBooks(List<ThanksBook> thanksBooks) {
    if (thanksBooks.isEmpty) {
      return 'لا يوجد';
    }
    return thanksBooks.map((book) {
      final date = DateFormat('yyyy-MM-dd').format(book.bookDate);
      return "رقم: ${book.bookNumber}, تاريخ: $date, شهور: ${book.monthsDeducted}, ملاحظات: ${book.notes.isNotEmpty ? book.notes : 'لا يوجد'}";
    }).join('; ');
  }

  static Future<void> generateRaiseReport(
      BuildContext context, List<Employee> employees) async {
    final List<List<dynamic>> rows = [];
    final notificationsProvider = context.read<NotificationsProvider>();

    rows.add([
      'اسم الموظف',
      'العنوان الوظيفي',
      'الراتب الحالي',
      'الراتب الجديد',
      'تاريخ الاستحقاق الحالي',
      'تاريخ الاستحقاق الجديد',
      'عنوان العمل',
      'كتب الشكر (الرقم، التاريخ، الشهور، الملاحظات)'
    ]);

    for (var employee in employees) {
      final currentSalary = employee.currentSalary;
      final nextSalary = currentSalary + employee.grade.annualRaise;
      final dueDate = notificationsProvider.calculateNextRaiseDate(employee);
      final newDueDate = DateTime(dueDate.year + 1, dueDate.month, dueDate.day);

      rows.add([
        employee.name,
        employee.jobTitle,
        currentSalary.toStringAsFixed(2),
        nextSalary.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd').format(dueDate),
        DateFormat('yyyy-MM-dd').format(newDueDate),
        employee.jobTitle,
        _formatThanksBooks(employee.thanksBooks),
      ]);
    }

    await _generateAndShareCsv(context, rows, 'raise_report');
  }

  static Future<void> generatePromotionReport(
      BuildContext context, List<Employee> employees, List<Grade> allGrades) async {
    final List<List<dynamic>> rows = [];
    final notificationsProvider = context.read<NotificationsProvider>();

    rows.add([
      'اسم الموظف',
      'العنوان الوظيفي الحالي',
      'العنوان الوظيفي الجديد',
      'الراتب الحالي',
      'الراتب الجديد',
      'تاريخ الاستحقاق الحالي',
      'تاريخ الاستحقاق الجديد',
      'كتب الشكر (الرقم، التاريخ، الشهور، الملاحظات)'
    ]);

    for (var employee in employees) {
      final currentGradeIndex =
          allGrades.indexWhere((g) => g.id == employee.grade.id);
      Grade? nextGrade =
          (currentGradeIndex != -1 && currentGradeIndex + 1 < allGrades.length)
              ? allGrades[currentGradeIndex + 1]
              : null;

      final currentSalary = employee.currentSalary;
      final newSalary = nextGrade?.baseSalary ?? currentSalary;
      final dueDate = notificationsProvider.calculateNextPromotionDate(employee);

      final newDueDate = dueDate != null
          ? DateTime(dueDate.year + 4, dueDate.month, dueDate.day)
          : null;

      rows.add([
        employee.name,
        employee.jobTitle,
        nextGrade?.title ?? 'الدرجة النهائية',
        currentSalary.toStringAsFixed(2),
        newSalary.toStringAsFixed(2),
        dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate) : 'غير محدد',
        newDueDate != null
            ? DateFormat('yyyy-MM-dd').format(newDueDate)
            : 'غير محدد',
        _formatThanksBooks(employee.thanksBooks),
      ]);
    }

    await _generateAndShareCsv(context, rows, 'promotion_report');
  }

  static Future<void> _generateAndShareCsv(
      BuildContext context, List<List<dynamic>> rows, String fileName) async {
    try {
      final String csv = const ListToCsvConverter().convert(rows);
      final box = context.findRenderObject() as RenderBox?;
      final subject = 'تقرير $fileName';

      if (kIsWeb) {
        // For web, encode to Uint8List and create XFile from data
        final Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
        final xFile = XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: '$fileName.csv',
          lastModified: DateTime.now(),
        );

        await Share.shareXFiles(
          [xFile],
          subject: subject,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        // For mobile/desktop, save to a temporary file
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/$fileName-${DateTime.now().millisecondsSinceEpoch}.csv';
        final File file = File(filePath);
        await file.writeAsString(csv, flush: true, encoding: utf8);

        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'text/csv')],
          subject: subject,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء التقرير: $e')),
      );
    }
  }
}
