
import 'package:flutter/foundation.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/employee_provider.dart';
import 'package:myapp/notifications_provider.dart';

class ReportsProvider with ChangeNotifier {
  final EmployeeProvider _employeeProvider;
  final NotificationsProvider _notificationsProvider; // To reuse calculation logic

  List<Employee> _raiseFilteredEmployees = [];
  List<Employee> _promotionFilteredEmployees = [];
  Map<String, int> _gradeDistribution = {};
  int _selectedMonth = 0; // 0 for All Year, 1-12 for months

  ReportsProvider(this._employeeProvider, this._notificationsProvider) {
    _employeeProvider.addListener(_updateReports);
    _updateReports();
  }

  @override
  void dispose() {
    _employeeProvider.removeListener(_updateReports);
    super.dispose();
  }

  // Getters
  List<Employee> get raiseFilteredEmployees => _raiseFilteredEmployees;
  List<Employee> get promotionFilteredEmployees => _promotionFilteredEmployees;
  Map<String, int> get gradeDistribution => _gradeDistribution;
  int get selectedMonth => _selectedMonth;

  // Logic
  void _updateReports() {
    final allEmployees = _employeeProvider.employees;

    // Filter employees based on the selected month
    _filterEmployeesByMonth(allEmployees);

    // Calculate grade distribution
    _calculateGradeDistribution(allEmployees);

    notifyListeners();
  }

  List<Employee> getEmployeesByGrade(String gradeTitle) {
    return _employeeProvider.employees
        .where((employee) => employee.grade.title == gradeTitle)
        .toList();
  }

  void _filterEmployeesByMonth(List<Employee> allEmployees) {
    _raiseFilteredEmployees = allEmployees.where((emp) {
      final nextRaiseDate = calculateNextRaiseDate(emp);
      if (nextRaiseDate == null) return false;
      if (_selectedMonth == 0) return true; // All year
      return nextRaiseDate.month == _selectedMonth;
    }).toList();

    _promotionFilteredEmployees = allEmployees.where((emp) {
      final nextPromotionDate = calculateNextPromotionDate(emp);
      if (nextPromotionDate == null) return false;
      if (_selectedMonth == 0) return true; // All year
      return nextPromotionDate.month == _selectedMonth;
    }).toList();
  }

  void _calculateGradeDistribution(List<Employee> allEmployees) {
    final distribution = <String, int>{};
    for (var employee in allEmployees) {
      distribution.update(employee.grade.title, (value) => value + 1, ifAbsent: () => 1);
    }
    _gradeDistribution = distribution;
  }

  void setMonthFilter(int month) {
    _selectedMonth = month;
    _updateReports(); // Re-filter and notify listeners
  }

  // Publicly expose calculation logic from notifications provider
  DateTime? calculateNextRaiseDate(Employee employee) {
    return _notificationsProvider.calculateNextRaiseDate(employee);
  }

  DateTime? calculateNextPromotionDate(Employee employee) {
    return _notificationsProvider.calculateNextPromotionDate(employee);
  }
}
