
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myapp/import_system/column_mapping_screen.dart';
import 'package:myapp/import_system/import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final ImportService _importService = ImportService();
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _pickedFile = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
        withData: true, // Ensure file bytes are loaded
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          _pickedFile = file;
        });

        // Automatically proceed to the next step
        await _processAndNavigate(file);

      } else {
        // User canceled the picker
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('تم إلغاء اختيار الملف.')),
          );
        }
      }
    } catch (e) {
      // Handle exceptions
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('حدث خطأ أثناء اختيار الملف: $e')),
        );
      }
    }
    finally {
      if (mounted) {
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  Future<void> _processAndNavigate(PlatformFile file) async {
    try {
      // Use file.bytes for cross-platform compatibility (especially web)
       final content = file.bytes;
       if (content == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لم يتم العثور على محتوى الملف.')),
            );
          }
          return;
       }

       final List<List<dynamic>> data = await _importService.parseFile(file.name, content);
      
       if (mounted) {
          if (data.isNotEmpty) {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ColumnMappingScreen(data: data),
              ),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('الملف فارغ أو تعذر تحليله.')),
            );
          }
       }

    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('خطأ في معالجة الملف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد البيانات'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.cloud_upload_outlined,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'اختر ملفًا لبدء عملية الاستيراد',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'يدعم التطبيق ملفات CSV, Excel (XLSX), و JSON.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('اختيار ملف'),
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              if (_pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(_pickedFile!.name),
                      subtitle: Text('${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
