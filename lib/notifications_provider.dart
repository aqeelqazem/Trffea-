
import 'package:flutter/foundation.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/employee_provider.dart';

class NotificationsProvider with ChangeNotifier {
  final EmployeeProvider _employeeProvider;

  NotificationsProvider(this._employeeProvider) {
    // Listen to changes in the main employee provider to refresh notifications
    _employeeProvider.addListener(_onEmployeeDataChanged);
    // Initial calculation
    _onEmployeeDataChanged();
  }

  List<Employee> _dueRaises = [];
  List<Employee> _upcomingRaises = [];
  List<Employee> _duePromotions = [];
  List<Employee> _upcomingPromotions = [];

  List<Employee> get dueRaises => _dueRaises;
  List<Employee> get upcomingRaises => _upcomingRaises;
  List<Employee> get duePromotions => _duePromotions;
  List<Employee> get upcomingPromotions => _upcomingPromotions;

  void _onEmployeeDataChanged() {
    final allEmployees = _employeeProvider.employees;
    final now = DateTime.now();

    _dueRaises = allEmployees.where((emp) {
      final nextRaiseDate = calculateNextRaiseDate(emp);
      return !now.isBefore(nextRaiseDate);
    }).toList();

    _upcomingRaises = allEmployees.where((emp) {
       final nextRaiseDate = calculateNextRaiseDate(emp);
       return now.isBefore(nextRaiseDate) && nextRaiseDate.month == now.month && nextRaiseDate.year == now.year;
    }).toList();

     _duePromotions = allEmployees.where((emp) {
      final nextPromotionDate = calculateNextPromotionDate(emp);
      return nextPromotionDate != null && !now.isBefore(nextPromotionDate);
    }).toList();

    _upcomingPromotions = allEmployees.where((emp) {
       final nextPromotionDate = calculateNextPromotionDate(emp);
       return nextPromotionDate != null && now.isBefore(nextPromotionDate) && nextPromotionDate.month == now.month && nextPromotionDate.year == now.year;
    }).toList();

    notifyListeners();
  }

   // --- Public Calculation Logic ---

  int calculateTotalPenaltyMonths(Employee emp) {
    return emp.penalties
        .where((p) => !p.isConsumed)
        .fold(0, (sum, p) => sum + p.delayInMonths);
  }

  DateTime calculateNextRaiseDate(Employee emp) {
    final baseRaiseDate = DateTime(
      emp.effectiveLastRaiseDate.year + 1,
      emp.effectiveLastRaiseDate.month,
      emp.effectiveLastRaiseDate.day,
    );
    final raiseYearStartDate = emp.effectiveLastRaiseDate;
    final applicableBooks = emp.thanksBooks.where((book) {
      return !book.isApplied &&
          !book.bookDate.isBefore(raiseYearStartDate) &&
          book.bookDate.isBefore(baseRaiseDate);
    }).toList();
    final totalMonthsToDeduct =
        applicableBooks.fold<int>(0, (sum, book) => sum + book.monthsDeducted);
    final totalPenaltyMonths = calculateTotalPenaltyMonths(emp);
    var adjustedRaiseDate = baseRaiseDate;
    for (int i = 0; i < totalMonthsToDeduct; i++) {
      adjustedRaiseDate = DateTime(adjustedRaiseDate.year,
          adjustedRaiseDate.month - 1, adjustedRaiseDate.day);
    }
    for (int i = 0; i < totalPenaltyMonths; i++) {
      adjustedRaiseDate = DateTime(adjustedRaiseDate.year,
          adjustedRaiseDate.month + 1, adjustedRaiseDate.day);
    }
    return adjustedRaiseDate;
  }

  DateTime? calculateNextPromotionDate(Employee emp) {
    if (emp.grade.raisesCount == null) return null;
    final basePromotionDate = DateTime(
      emp.lastPromotionDate.year + emp.grade.raisesCount!,
      emp.lastPromotionDate.month,
      emp.lastPromotionDate.day,
    );
    final totalThanksMonths =
        emp.thanksBooks.fold<int>(0, (sum, book) => sum + book.monthsDeducted);
    final totalPenaltyMonths = calculateTotalPenaltyMonths(emp);
    var adjustedPromotionDate = basePromotionDate;
    for (int i = 0; i < totalThanksMonths; i++) {
      adjustedPromotionDate = DateTime(adjustedPromotionDate.year,
          adjustedPromotionDate.month - 1, adjustedPromotionDate.day);
    }
     for (int i = 0; i < totalPenaltyMonths; i++) {
      adjustedPromotionDate = DateTime(adjustedPromotionDate.year,
          adjustedPromotionDate.month + 1, adjustedPromotionDate.day);
    }
    return adjustedPromotionDate;
  }

  String calculateDifference(DateTime dueDate) {
    final difference = DateTime.now().difference(dueDate);
    if (difference.isNegative) return ''; // Not due yet

    int days = difference.inDays;
    if (days == 0) return 'اليوم';

    int months = (days / 30).floor();
    days = days % 30;

    String result = 'متأخر ';
    if (months > 0) {
      result += '$months شهر';
      if (days > 0) result += ' و ';
    }
    if (days > 0) {
      result += '$days يوم';
    }
    return result.trim();
  }


  @override
  void dispose() {
    _employeeProvider.removeListener(_onEmployeeDataChanged);
    super.dispose();
  }
}
