import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/certificate_allowance_data.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/employee_provider.dart';
import 'package:provider/provider.dart';

// Helper class for dynamic allowances
class _CustomAllowance {
  final String id;
  final TextEditingController nameController;
  final TextEditingController percentageController;
  double calculatedValue = 0.0;

  _CustomAllowance({String name = '', String percentage = '0'})
    : id = UniqueKey().toString(),
      nameController = TextEditingController(text: name),
      percentageController = TextEditingController(text: percentage);

  void dispose() {
    nameController.dispose();
    percentageController.dispose();
  }
}

// Helper class for dynamic deductions
class _CustomDeduction {
  final String id;
  final TextEditingController nameController;
  final TextEditingController amountController;

  _CustomDeduction({String name = '', String amount = '0'})
    : id = UniqueKey().toString(),
      nameController = TextEditingController(text: name),
      amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class TotalSalaryScreen extends StatefulWidget {
  final Employee employee;

  const TotalSalaryScreen({super.key, required this.employee});

  @override
  State<TotalSalaryScreen> createState() => _TotalSalaryScreenState();
}

class _TotalSalaryScreenState extends State<TotalSalaryScreen> {
  late final TextEditingController _nominalSalaryController;
  late final TextEditingController _dangerAllowancePercentageController;
  late final TextEditingController _familyAllowanceController;
  late String _selectedEducationLevel;

  final List<_CustomAllowance> _otherAllowances = [];
  final List<_CustomDeduction> _otherDeductions = [];

  double _certificateAllowanceValue = 0.0;
  double _dangerAllowanceValue = 0.0;
  double _retirementDeduction = 0.0;
  double _totalSalary = 0.0;

  @override
  void initState() {
    super.initState();
    // --- Load Saved Data ---
    _nominalSalaryController = TextEditingController(
      text: widget.employee.currentSalary.toString(),
    );
    _dangerAllowancePercentageController = TextEditingController(
      text: widget.employee.dangerAllowancePercentage.toString(),
    );
    _familyAllowanceController = TextEditingController(
      text: widget.employee.familyAllowance.toString(),
    );

    for (var allowance in widget.employee.customAllowances) {
      _otherAllowances.add(
        _CustomAllowance(
          name: allowance.name,
          percentage: allowance.percentage.toString(),
        ),
      );
    }

    for (var deduction in widget.employee.customDeductions) {
      _otherDeductions.add(
        _CustomDeduction(
          name: deduction.name,
          amount: deduction.amount.toString(),
        ),
      );
    }

    _selectedEducationLevel =
        educationLevels.contains(widget.employee.education)
        ? widget.employee.education
        : 'بدون شهادة';

    // --- Add Listeners ---
    _nominalSalaryController.addListener(_calculateAll);
    _dangerAllowancePercentageController.addListener(_calculateAll);
    _familyAllowanceController.addListener(_calculateAll);
    for (var allowance in _otherAllowances) {
      allowance.percentageController.addListener(_calculateAll);
    }
    for (var deduction in _otherDeductions) {
      deduction.amountController.addListener(_calculateAll);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateAll());
  }

  void _calculateAll() {
    final double nominalSalary =
        double.tryParse(_nominalSalaryController.text) ?? 0.0;
    final double dangerPercentage =
        double.tryParse(_dangerAllowancePercentageController.text) ?? 0.0;
    final double familyAllowance =
        double.tryParse(_familyAllowanceController.text) ?? 0.0;

    final double allowancePercentage =
        certificateAllowances[_selectedEducationLevel] ?? 0.0;
    _certificateAllowanceValue = nominalSalary * allowancePercentage;
    _dangerAllowanceValue = nominalSalary * (dangerPercentage / 100);

    double totalOtherAllowancesValue = 0;
    for (var allowance in _otherAllowances) {
      final double percentage =
          double.tryParse(allowance.percentageController.text) ?? 0.0;
      allowance.calculatedValue = nominalSalary * (percentage / 100);
      totalOtherAllowancesValue += allowance.calculatedValue;
    }

    _retirementDeduction = nominalSalary * 0.10;
    double totalOtherDeductionsValue = 0;
    for (var deduction in _otherDeductions) {
      totalOtherDeductionsValue +=
          double.tryParse(deduction.amountController.text) ?? 0.0;
    }

    final totalAllowances =
        _certificateAllowanceValue +
        _dangerAllowanceValue +
        familyAllowance +
        totalOtherAllowancesValue;
    final totalDeductions = _retirementDeduction + totalOtherDeductionsValue;

    _totalSalary = (nominalSalary + totalAllowances) - totalDeductions;

    if (mounted) {
      setState(() {});
    }
  }

  void _addOtherAllowance() {
    setState(() {
      final newAllowance = _CustomAllowance();
      newAllowance.percentageController.addListener(_calculateAll);
      _otherAllowances.add(newAllowance);
    });
    _calculateAll();
  }

  void _removeOtherAllowance(String id) {
    setState(() {
      final allowanceToRemove = _otherAllowances.firstWhere((a) => a.id == id);
      allowanceToRemove.dispose();
      _otherAllowances.removeWhere((a) => a.id == id);
    });
    _calculateAll();
  }

  void _addOtherDeduction() {
    setState(() {
      final newDeduction = _CustomDeduction();
      newDeduction.amountController.addListener(_calculateAll);
      _otherDeductions.add(newDeduction);
    });
    _calculateAll();
  }

  void _removeOtherDeduction(String id) {
    setState(() {
      final deductionToRemove = _otherDeductions.firstWhere((d) => d.id == id);
      deductionToRemove.dispose();
      _otherDeductions.removeWhere((d) => d.id == id);
    });
    _calculateAll();
  }

  void _saveSalaryDetails() {
    final updatedEmployee = widget.employee.copyWith(
      currentSalary:
          int.tryParse(_nominalSalaryController.text) ??
          widget.employee.currentSalary,
      dangerAllowancePercentage:
          double.tryParse(_dangerAllowancePercentageController.text) ?? 0.0,
      familyAllowance: double.tryParse(_familyAllowanceController.text) ?? 0.0,
      education:
          _selectedEducationLevel, // Also save the selected education level
      customAllowances: _otherAllowances
          .map(
            (a) => CustomAllowance(
              name: a.nameController.text,
              percentage: double.tryParse(a.percentageController.text) ?? 0.0,
            ),
          )
          .toList(),
      customDeductions: _otherDeductions
          .map(
            (d) => CustomDeduction(
              name: d.nameController.text,
              amount: double.tryParse(d.amountController.text) ?? 0.0,
            ),
          )
          .toList(),
    );

    Provider.of<EmployeeProvider>(
      context,
      listen: false,
    ).updateEmployee(updatedEmployee);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ تفاصيل الراتب بنجاح!')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nominalSalaryController.dispose();
    _dangerAllowancePercentageController.dispose();
    _familyAllowanceController.dispose();
    for (var allowance in _otherAllowances) {
      allowance.dispose();
    }
    for (var deduction in _otherDeductions) {
      deduction.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.decimalPattern('ar');

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل راتب ${widget.employee.name}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
            child: Column(
              children: [
                _buildMainSalaryCard(),
                const SizedBox(height: 16),
                _buildAllowancesCard(currencyFormat, isWideScreen),
                const SizedBox(height: 16),
                _buildDeductionsCard(currencyFormat, isWideScreen),
                const SizedBox(height: 24),
                _buildTotalCard(currencyFormat),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSalaryDetails,
        icon: const Icon(Icons.save),
        label: const Text('حفظ التغييرات'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMainSalaryCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('الراتب الأساسي'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nominalSalaryController,
              label: 'الراتب الاسمي',
              icon: Icons.monetization_on_outlined,
              isNumeric: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllowancesCard(NumberFormat currencyFormat, bool isWideScreen) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('المخصصات'),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'مخصصات الشهادة',
              icon: Icons.school_outlined,
            ),
            _buildReadOnlyField(
              label: 'قيمة مخصصات الشهادة',
              value: currencyFormat.format(_certificateAllowanceValue),
              icon: Icons.star_border_purple500_sharp,
            ),
            const Divider(),
            _buildTextField(
              controller: _dangerAllowancePercentageController,
              label: 'نسبة مخصصات الخطورة',
              icon: Icons.warning_amber_rounded,
              isPercentage: true,
              isNumeric: true,
            ),
            _buildReadOnlyField(
              label: 'قيمة مخصصات الخطورة',
              value: currencyFormat.format(_dangerAllowanceValue),
              icon: Icons.shield_outlined,
            ),
            const Divider(),
            _buildTextField(
              controller: _familyAllowanceController,
              label: 'مخصصات الزوجية والأطفال',
              icon: Icons.family_restroom_outlined,
              isNumeric: true,
            ),
            const Divider(height: 30),
            _buildSectionTitle('مخصصات أخرى (نسبة مئوية)'),
            ..._buildOtherAllowances(currencyFormat, isWideScreen),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة مخصصات أخرى'),
                onPressed: _addOtherAllowance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionsCard(NumberFormat currencyFormat, bool isWideScreen) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('الاستقطاعات والخصومات'),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              label: 'خصم التقاعد (10% من الاسمي)',
              value: currencyFormat.format(_retirementDeduction),
              icon: Icons.trending_down,
              valueColor: Colors.red.shade700,
            ),
            const Divider(height: 30),
            _buildSectionTitle('خصومات أخرى (مبلغ ثابت)'),
            ..._buildOtherDeductions(isWideScreen),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة خصم آخر'),
                onPressed: _addOtherDeduction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  List<Widget> _buildOtherAllowances(
    NumberFormat currencyFormat,
    bool isWideScreen,
  ) {
    return _otherAllowances.map((allowance) {
      final nameField = _buildTextField(
        controller: allowance.nameController,
        label: 'اسم المخصص',
        icon: Icons.label_important_outline,
        small: true,
      );
      final percentageField = _buildTextField(
        controller: allowance.percentageController,
        label: 'النسبة',
        icon: Icons.percent,
        isPercentage: true,
        isNumeric: true,
        small: true,
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 3, child: nameField),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: percentageField),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeOtherAllowance(allowance.id),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      nameField,
                      percentageField,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeOtherAllowance(allowance.id),
                        ),
                      ),
                    ],
                  ),
            _buildReadOnlyField(
              label: 'القيمة المحسوبة',
              value: currencyFormat.format(allowance.calculatedValue),
              icon: Icons.attach_money,
              small: true,
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildOtherDeductions(bool isWideScreen) {
    return _otherDeductions.map((deduction) {
      final nameField = _buildTextField(
        controller: deduction.nameController,
        label: 'اسم الخصم',
        icon: Icons.label_important_outline,
        small: true,
      );
      final amountField = _buildTextField(
        controller: deduction.amountController,
        label: 'المبلغ',
        icon: Icons.money_off,
        isNumeric: true,
        small: true,
      );
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: isWideScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: nameField),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: amountField),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeOtherDeduction(deduction.id),
                  ),
                ],
              )
            : Column(
                children: [
                  nameField,
                  amountField,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeOtherDeduction(deduction.id),
                    ),
                  ),
                ],
              ),
      );
    }).toList();
  }

  Widget _buildTotalCard(NumberFormat currencyFormat) {
    return Card(
      elevation: 4.0,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildReadOnlyField(
          label: 'الراتب الكلي النهائي',
          value: currencyFormat.format(_totalSalary),
          icon: Icons.account_balance_wallet,
          isTotal: true,
          valueColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPercentage = false,
    bool isNumeric = false,
    bool small = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 4.0 : 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.labelLarge,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffix: isNumeric
              ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    isPercentage ? '%' : 'دينار',
                    style: textTheme.labelMedium,
                  ),
                )
              : null,
          contentPadding: small
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required IconData icon}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedEducationLevel,
        style: textTheme.bodyLarge,
        items: educationLevels.map((String level) {
          return DropdownMenuItem<String>(value: level, child: Text(level));
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedEducationLevel = newValue;
              _calculateAll();
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.labelLarge,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    bool isTotal = false,
    bool small = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = small
        ? textTheme.bodyMedium
        : (isTotal ? textTheme.titleLarge : textTheme.bodyLarge);
    final valueStyle = TextStyle(
      fontSize: small ? 16 : (isTotal ? 28 : 18),
      fontWeight: FontWeight.bold,
      color: valueColor ?? textTheme.bodyLarge?.color,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 6.0 : 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
            size: small ? 20 : 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8.0, // gap between items
              runSpacing: 4.0, // gap between lines
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('$label:', style: titleStyle),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
