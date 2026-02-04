
import 'package:flutter/material.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/employee_provider.dart';
import 'package:myapp/grade_model.dart';
import 'package:provider/provider.dart';

// 1. Added "معلومة إضافية" to the list of options.
const List<String> _targetEmployeeFields = [
  'اسم الموظف',
  'العنوان الوظيفي',
  'التحصيل الدراسي',
  'الراتب الحالي',
  'تاريخ آخر ترفيع',
  'تاريخ آخر علاوة فعلي',
  'عدد العلاوات المستلمة',
  'الدرجة الوظيفية',
  'معلومة إضافية', // The new option for additional info
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
      // Prioritize direct matches before contains
      for (String field in _targetEmployeeFields) {
        if (headers[i] == field.toLowerCase()) {
          bestMatch = field;
          break;
        }
      }
       // If no direct match, try partial match
      if (bestMatch == 'تجاهل هذا العمود') {
         for (String field in _targetEmployeeFields) {
           if (field != 'تجاهل هذا العمود' && headers[i].contains(field.toLowerCase())) {
             bestMatch = field;
             break;
           }
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
      final additionalInfo = <String>[];

      // 2. Correctly process mappings based on user selection.
      for (final entry in _columnMappings.entries) {
        final columnIndex = entry.key;
        final targetField = entry.value;

        if (columnIndex >= row.length) continue; // Skip if row is shorter than expected.
        
        final cellValue = row[columnIndex];

        if (targetField == 'معلومة إضافية') {
          if (cellValue != null && cellValue.toString().trim().isNotEmpty) {
            additionalInfo.add(cellValue.toString().trim());
          }
        } else if (targetField != 'تجاهل هذا العمود') {
          employeeData[targetField] = cellValue;
        }
        // If the field is "تجاهل هذا العمود", we explicitly do nothing.
      }

      try {
        final nameValue = employeeData['اسم الموظف']?.toString().trim();
        if (nameValue == null || nameValue.isEmpty) {
           _showErrorDialog('خطأ في الاستيراد', 'قيمة "اسم الموظف" فارغة في الصف رقم $rowNumber. هذا الحقل إجباري.');
           return;
        }

        final gradeValue = employeeData['الدرجة الوظيفية']?.toString().trim();
        if (gradeValue == null || gradeValue.isEmpty) {
          _showErrorDialog('خطأ في الاستيراد', 'قيمة "الدرجة الوظيفية" فارغة في الصف رقم $rowNumber. هذا الحقل إجباري.');
          return;
        }
        
        Grade? grade;
        final int? gradeId = int.tryParse(gradeValue);

        if (gradeId != null) {
          try {
            grade = allGrades.firstWhere((g) => g.id == gradeId);
          } catch (e) {
            grade = null;
          }
        } else {
          try {
            grade = allGrades.firstWhere((g) => g.title == gradeValue);
          } catch (e) {
            grade = null;
          }
        }

        if (grade == null) {
          throw StateError('Grade not found');
        }

        final employee = Employee(
          id: DateTime.now().millisecondsSinceEpoch.toString() + row.hashCode.toString(),
          name: nameValue,
          jobTitle: employeeData['العنوان الوظيفي']?.toString().trim() ?? '',
          education: employeeData['التحصيل الدراسي']?.toString().trim() ?? '',
          grade: grade,
          lastPromotionDate: _parseDate(employeeData['تاريخ آخر ترفيع']) ?? DateTime.now(),
          effectiveLastRaiseDate: _parseDate(employeeData['تاريخ آخر علاوة فعلي']) ?? _parseDate(employeeData['تاريخ آخر ترفيع']) ?? DateTime.now(),
          raisesReceived: _parseInt(employeeData['عدد العلاوات المستلمة']),
          currentSalary: _parseDouble(employeeData['الراتب الحالي']).toInt(),
          startDate: DateTime.now(), // Consider making this configurable
          additionalInfo: additionalInfo, // Assign the correctly gathered info
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
    final String stringValue = value.toString().trim();
    if (stringValue.isEmpty) return null;

    final double? excelDate = double.tryParse(stringValue);
     if (excelDate != null && excelDate > 40000 && excelDate < 50000) { // Simple check for Excel serial date
      return DateTime.fromMicrosecondsSinceEpoch(((excelDate - 25569) * 86400000 * 1000).toInt(), isUtc: true);
    }
    return DateTime.tryParse(stringValue);
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
                              'لكل عمود من ملفك المصدر، اختر الحقل المناسب له في التطبيق من القائمة المنسدلة.\n\n- **اسم الموظف والدرجة الوظيفية:** حقول إجبارية.\n- **معلومة إضافية:** اختر هذا الخيار للأعمدة التي تحتوي على بيانات تريد إضافتها كمعلومات إضافية للموظف.\n- **تجاهل هذا العمود:** لاستثناء الحقل من عملية الاستيراد بالكامل.'),
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
                        if (sampleData.length > index && sampleData[index].toString().isNotEmpty)
                          Text(
                            'مثال: "${sampleData[index]}"',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _columnMappings[index],
                          items: _targetEmployeeFields.map((field) {
                            return DropdownMenuItem(
                              value: field,
                              child: Text(field),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _columnMappings[index] = newValue!;
                            });
                          },
                          isExpanded: true,
                           decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
