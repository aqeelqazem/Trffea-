
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import './employee_provider.dart';
import './thanks_book_model.dart';

class ThanksBookScreen extends StatefulWidget {
  final String employeeId;
  final ThanksBook? existingBook;

  const ThanksBookScreen({super.key, required this.employeeId, this.existingBook});

  @override
  State<ThanksBookScreen> createState() => _ThanksBookScreenState();
}

class _ThanksBookScreenState extends State<ThanksBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bookNumberController;
  late TextEditingController _monthsDeductedController;
  late TextEditingController _notesController; // New controller
  late DateTime _bookDate;

  bool get _isEditing => widget.existingBook != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _bookNumberController = TextEditingController(text: widget.existingBook!.bookNumber);
      _monthsDeductedController = TextEditingController(text: widget.existingBook!.monthsDeducted.toString());
      _notesController = TextEditingController(text: widget.existingBook!.notes); // Initialize with existing notes
      _bookDate = widget.existingBook!.bookDate;
    } else {
      _bookNumberController = TextEditingController();
      _monthsDeductedController = TextEditingController(text: '1');
      _notesController = TextEditingController(); // Initialize empty
      _bookDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _bookNumberController.dispose();
    _monthsDeductedController.dispose();
    _notesController.dispose(); // Dispose the new controller
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _bookDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _bookDate) {
      setState(() => _bookDate = picked);
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<EmployeeProvider>(context, listen: false);

      final newBook = ThanksBook(
        id: _isEditing ? widget.existingBook!.id : const Uuid().v4(),
        bookNumber: _bookNumberController.text,
        bookDate: _bookDate,
        monthsDeducted: int.tryParse(_monthsDeductedController.text) ?? 1,
        notes: _notesController.text, // Save notes
        isApplied: _isEditing ? widget.existingBook!.isApplied : false,
      );

      bool success = _isEditing
          ? provider.updateThanksBook(widget.employeeId, newBook)
          : provider.addThanksBook(widget.employeeId, newBook);

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم كتاب الشكر موجود مسبقاً لهذا الموظف. يرجى استخدام رقم آخر.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل كتاب الشكر' : 'إضافة كتاب شكر جديد'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _bookNumberController,
                  decoration: const InputDecoration(labelText: 'رقم الكتاب', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال رقم الكتاب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthsDeductedController,
                  decoration: const InputDecoration(labelText: 'يختزل (أشهر)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || int.tryParse(value) == null || int.parse(value) < 1)
                      ? 'يرجى إدخال عدد صحيح للأشهر'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
                  maxLines: 3, // Allow multiple lines for notes
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ الكتاب'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_bookDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: _saveForm,
                  child: Text(_isEditing ? 'حفظ التغييرات' : 'إضافة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
