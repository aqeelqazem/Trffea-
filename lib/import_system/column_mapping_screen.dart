
import 'package:flutter/material.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/employee_provider.dart';
import 'package:myapp/grade_model.dart';
import 'package:provider/provider.dart';

const List<String> _targetEmployeeFields = [
  'اسم الموظف',
  'العنوان الوظيفي',
  'التحصيل الدراسي',
  'الراتب الحالي',
  'تاريخ آخر ترفيع',
  'تاريخ آخر علاوة فعلي',
  'عدد العلاوات المستلمة',
  'الدرجة الوظيفية',
  'تجاهل هذا العمود',
];

class ColumnMappingScreen extends StatefulWidget {
  final List<List<dynamic>> data;

  const ColumnMappingScreen({super.key, required this.data});

  @override
  State<ColumnMappingScreen> createState() => _ColumnMappingScreenState();
}

class _ColumnMappingScreenState extends State<ColumnMappingScreen> {
  late Map<int, String> _columnMappings;

  @override
  void initState() {
    super.initState();
    _columnMappings = {};
    _autoMapHeaders();
  }

  void _autoMapHeaders() {
    if (widget.data.isEmpty) return;
    final headers = widget.data.first.map((h) => h.toString().toLowerCase().trim()).toList();

    for (int i = 0; i < headers.length; i++) {
      String bestMatch = 'تجاهل هذا العمود';
      for (String field in _targetEmployeeFields) {
        if (headers[i].contains(field.toLowerCase())) {
          bestMatch = field;
          break;
        }
      }
      _columnMappings[i] = bestMatch;
    }
  }

  Future<void> _showErrorDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: <Widget>[
            TextButton(
              child: const Text('حسنًا'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _processAndImportData() {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final allGrades = employeeProvider.grades;
    final dataRows = widget.data.skip(1);

    final newEmployees = <Employee>[];
    int rowNumber = 1;

    for (final row in dataRows) {
      rowNumber++;
      final employeeData = <String, dynamic>{};
      for (final entry in _columnMappings.entries) {
        final columnIndex = entry.key;
        final targetField = entry.value;
        if (targetField != 'تجاهل هذا العمود' && columnIndex < row.length) {
          employeeData[targetField] = row[columnIndex];
        }
      }

      try {
        final gradeValue = employeeData['الدرجة الوظيفية']?.toString().trim();
        if (gradeValue == null || gradeValue.isEmpty) {
          _showErrorDialog('خطأ في الاستيراد', 'قيمة الدرجة الوظيفية فارغة في الصف رقم $rowNumber. يرجى إصلاح البيانات والمحاولة مرة أخرى.');
          return;
        }

        Grade? grade;
        final int? gradeId = int.tryParse(gradeValue);

        if (gradeId != null) {
          // It's a number, try to find by ID
          try {
            grade = allGrades.firstWhere((g) => g.id == gradeId);
          } catch (e) {
            grade = null;
          }
        } else {
          // It's a string, try to find by title
          try {
            grade = allGrades.firstWhere((g) => g.title == gradeValue);
          } catch (e) {
            grade = null;
          }
        }

        if (grade == null) {
          // If still null after both checks, throw the error
          throw StateError('Grade not found');
        }

        final employee = Employee(
          id: DateTime.now().millisecondsSinceEpoch.toString() + row.hashCode.toString(),
          name: employeeData['اسم الموظف']?.toString().trim() ?? 'اسم غير متوفر',
          jobTitle: employeeData['العنوان الوظيفي']?.toString().trim() ?? '',
          education: employeeData['التحصيل الدراسي']?.toString().trim() ?? '',
          grade: grade,
          lastPromotionDate: _parseDate(employeeData['تاريخ آخر ترفيع']) ?? DateTime.now(),
          effectiveLastRaiseDate: _parseDate(employeeData['تاريخ آخر علاوة فعلي']) ?? DateTime.now(),
          raisesReceived: _parseInt(employeeData['عدد العلاوات المستلمة']),
          currentSalary: _parseDouble(employeeData['الراتب الحالي']).toInt(),
          startDate: DateTime.now(),
        );
        newEmployees.add(employee);

      } on StateError {
        final problematicValue = employeeData['الدرجة الوظيفية']?.toString().trim() ?? '[فارغ]';
        _showErrorDialog(
          'خطأ في الاستيراد',
          'حدث خطأ في الصف رقم $rowNumber.\n\nتعذر العثور على درجة وظيفية مطابقة للقيمة: "$problematicValue".\n\nيرجى التأكد من أن القيمة في ملفك هي إما رقم الدرجة (1-10) أو اسمها بالعربية (الأولى, الثانية, ...).\n\nتم إيقاف عملية الاستيراد.',
        );
        return;

      } catch (e) {
        _showErrorDialog('خطأ غير متوقع', 'حدث خطأ أثناء معالجة الصف رقم $rowNumber: $e');
        return;
      }
    }

    if (newEmployees.isNotEmpty) {
      employeeProvider.addMultipleEmployees(newEmployees);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم استيراد ${newEmployees.length} موظف بنجاح!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final double? excelDate = double.tryParse(value.toString());
    if (excelDate != null) {
      return DateTime.fromMillisecondsSinceEpoch(((excelDate - 25569) * 86400000).toInt());
    }
    return DateTime.tryParse(value.toString());
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString().trim()) ?? 0;
  }

   double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final headers = widget.data.isNotEmpty ? widget.data.first : [];
    final sampleData = widget.data.length > 1 ? widget.data[1] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط الأعمدة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Text('كيفية ربط الأعمدة'),
                        content: const SingleChildScrollView(
                          child: Text(
                              'لكل عمود من ملفك المصدر، اختر الحقل المناسب له في التطبيق من القائمة المنسدلة.\n\n- **اسم الموظف:** حقل إجباري.\n- **الدرجة الوظيفية:** يجب أن تطابق إحدى الدرجات المعرفة في التطبيق (مثال: الدرجة الأولى).\n- **التواريخ:** يجب أن تكون بصيغة (YYYY-MM-DD).\n- **الأرقام:** سيتم تحويلها تلقائيًا.\n- **تجاهل هذا العمود:** لاستثناء الحقل من عملية الاستيراد.'),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('حسنًا'),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        ],
                      ));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: headers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عمود ${index + 1}: ${headers[index]}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (sampleData.length > index)
                          Text(
                            'مثال: "${sampleData[index]}"',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        const SizedBox(height: 10),
                        FormField<String>(
                          initialValue: _columnMappings[index],
                          builder: (FormFieldState<String> state) {
                            return DropdownButton<String>(
                              value: state.value,
                              items: _targetEmployeeFields.map((field) {
                                return DropdownMenuItem(
                                  value: field,
                                  child: Text(field),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _columnMappings[index] = newValue!;
                                  state.didChange(newValue);
                                });
                              },
                              isExpanded: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تأكيد و استيراد'),
              onPressed: _processAndImportData,
               style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: Theme.of(context).textTheme.titleLarge,
                  ),
            ),
          )
        ],
      ),
    );
  }
}
