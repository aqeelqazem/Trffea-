
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

class ImportService {

  Future<List<List<dynamic>>> parseFile(String fileName, Uint8List fileBytes) async {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'csv':
        return _parseCsv(fileBytes);
      case 'xlsx':
        return _parseExcel(fileBytes);
      case 'json':
        return _parseJson(fileBytes);
      default:
        throw Exception('نوع الملف غير مدعوم: $extension');
    }
  }

  List<List<dynamic>> _parseCsv(Uint8List bytes) {
    // افتراض ترميز UTF-8
    final csvString = utf8.decode(bytes);
    const converter = CsvToListConverter();
    return converter.convert(csvString);
  }

  List<List<dynamic>> _parseExcel(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<List<dynamic>> data = [];

    if (excel.tables.keys.isNotEmpty) {
      var sheet = excel.tables[excel.tables.keys.first]; // قراءة أول ورقة عمل
      if (sheet != null) {
        for (var row in sheet.rows) {
          // تحويل خلايا البيانات إلى قيم نصية
          data.add(row.map((cell) => cell?.value.toString() ?? '').toList());
        }
      }
    }
    return data;
  }

   List<List<dynamic>> _parseJson(Uint8List bytes) {
    final jsonString = utf8.decode(bytes);
    final jsonData = json.decode(jsonString);

    if (jsonData is! List) {
      throw Exception('ملف JSON يجب أن يحتوي على مصفوفة من الكائنات.');
    }

    List<Map<String, dynamic>> listObjects = List<Map<String, dynamic>>.from(jsonData);

    if (listObjects.isEmpty) {
      return [];
    }

    // استخراج الأعمدة من أول كائن
    List<String> headers = listObjects.first.keys.toList();
    
    List<List<dynamic>> data = [headers]; // إضافة العناوين كأول صف

    // إضافة الصفوف
    for (var obj in listObjects) {
      List<dynamic> row = [];
      for (var header in headers) {
        row.add(obj[header]);
      }
      data.add(row);
    }
    
    return data;
  }

}
