
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import './employee_model.dart';
import './employee_provider.dart';
import './grade_model.dart';
import './grade_data.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? existingEmployee;

  const AddEmployeeScreen({super.key, this.existingEmployee});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _educationController;
  late TextEditingController _currentSalaryController;
  late Grade _selectedGrade;
  late DateTime _lastPromotionDate;
  late DateTime _effectiveLastRaiseDate;
  late TextEditingController _raisesReceivedController;

  bool get _isEditing => widget.existingEmployee != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final emp = widget.existingEmployee!;
      _nameController = TextEditingController(text: emp.name);
      _jobTitleController = TextEditingController(text: emp.jobTitle);
      _educationController = TextEditingController(text: emp.education);
      _currentSalaryController = TextEditingController(text: emp.currentSalary.toString());
      _selectedGrade = gradesData.firstWhere((g) => g.id == emp.grade.id, orElse: () => gradesData.last);
      _lastPromotionDate = emp.lastPromotionDate;
      _effectiveLastRaiseDate = emp.effectiveLastRaiseDate;
      _raisesReceivedController = TextEditingController(text: emp.raisesReceived.toString());
    } else {
      _nameController = TextEditingController();
      _jobTitleController = TextEditingController();
      _educationController = TextEditingController();
      _selectedGrade = gradesData.last; // Default to the last (lowest) grade
      _currentSalaryController = TextEditingController(text: _selectedGrade.baseSalary.toString());
      final now = DateTime.now();
      _lastPromotionDate = now;
      _effectiveLastRaiseDate = now;
      _raisesReceivedController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _educationController.dispose();
    _currentSalaryController.dispose();
    _raisesReceivedController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required String field}) async {
    final initialDate = field == 'promotion' ? _lastPromotionDate : _effectiveLastRaiseDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (field == 'promotion') {
          _lastPromotionDate = picked;
          if (picked.isAfter(_effectiveLastRaiseDate)) {
            _effectiveLastRaiseDate = picked;
          }
        } else {
          _effectiveLastRaiseDate = picked;
        }
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final effectiveDate = _isEditing && (int.tryParse(_raisesReceivedController.text) ?? 0) == 0
          ? _lastPromotionDate
          : _effectiveLastRaiseDate;

      final employee = Employee(
        id: _isEditing ? widget.existingEmployee!.id : const Uuid().v4(),
        name: _nameController.text,
        jobTitle: _jobTitleController.text,
        education: _educationController.text,
        grade: _selectedGrade,
        currentSalary: int.tryParse(_currentSalaryController.text) ?? _selectedGrade.baseSalary,
        startDate: _lastPromotionDate, 
        lastPromotionDate: _lastPromotionDate,
        effectiveLastRaiseDate: effectiveDate,
        raisesReceived: int.tryParse(_raisesReceivedController.text) ?? 0,
        thanksBooks: _isEditing ? widget.existingEmployee!.thanksBooks : [],
      );

      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      if (_isEditing) {
        provider.updateEmployee(employee);
        Navigator.of(context).pop(employee);
      } else {
        provider.addEmployee(employee);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل بيانات الموظف' : 'إضافة موظف جديد'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم الموظف', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال اسم الموظف' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jobTitleController,
                  decoration: const InputDecoration(labelText: 'العنوان الوظيفي', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(labelText: 'التحصيل الدراسي', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Grade>(
                  initialValue: _selectedGrade, // Use initialValue instead of value
                  decoration: const InputDecoration(labelText: 'الدرجة الوظيفية', border: OutlineInputBorder()),
                  items: gradesData.map<DropdownMenuItem<Grade>>((Grade grade) {
                    return DropdownMenuItem<Grade>(value: grade, child: Text(grade.title));
                  }).toList(),
                  onChanged: (Grade? newValue) {
                    setState(() {
                      _selectedGrade = newValue!;
                      if (!_isEditing) {
                        _currentSalaryController.text = _selectedGrade.baseSalary.toString();
                      }
                    });
                  },
                  validator: (value) => value == null ? 'يرجى اختيار درجة' : null,
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  controller: _currentSalaryController,
                  readOnly: !_isEditing, // Make it read-only for new employees
                  decoration: InputDecoration(
                    labelText: 'الراتب الإجمالي الحالي',
                    border: const OutlineInputBorder(),
                    fillColor: !_isEditing ? Theme.of(context).colorScheme.surfaceContainerHighest : null, // Use surfaceContainerHighest
                    filled: !_isEditing,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'يرجى إدخال رقم صحيح' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _raisesReceivedController,
                  decoration: const InputDecoration(labelText: 'عدد العلاوات المستلمة', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'يرجى إدخال عدد صحيح' : null,
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ آخر ترفيع'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_lastPromotionDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, field: 'promotion'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ آخر علاوة فعلي'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_effectiveLastRaiseDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, field: 'effective'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveForm,
                  child: Text(_isEditing ? 'حفظ التغييرات' : 'إضافة الموظف'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
