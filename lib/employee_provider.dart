
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/grade_model.dart';
import 'package:myapp/grade_data.dart';
import 'package:myapp/penalty_model.dart';
import 'package:myapp/thanks_book_model.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  static const _employeesKey = 'employees_key';

  List<Employee> get employees => _employees;
  List<Grade> get grades => gradesData; // Expose grades for mapping

  EmployeeProvider() {
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? employeesString = prefs.getString(_employeesKey);
    if (employeesString != null) {
      final List<dynamic> employeeJson = json.decode(employeesString);
      _employees = employeeJson.map((json) => Employee.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final String employeesString =
        json.encode(_employees.map((e) => e.toJson()).toList());
    await prefs.setString(_employeesKey, employeesString);
  }

  void addEmployee(Employee employee) {
    _employees.add(employee);
    _saveEmployees();
    notifyListeners();
  }

    void addMultipleEmployees(List<Employee> newEmployees) {
    _employees.addAll(newEmployees);
    _saveEmployees();
    notifyListeners();
  }


  void updateEmployee(Employee updatedEmployee) {
    final index = _employees.indexWhere((emp) => emp.id == updatedEmployee.id);
    if (index != -1) {
      _employees[index] = updatedEmployee;
      _saveEmployees();
      notifyListeners();
    }
  }

  void deleteEmployee(String employeeId) {
    _employees.removeWhere((emp) => emp.id == employeeId);
    _saveEmployees();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _employees = [];
    await _saveEmployees();
    notifyListeners();
  }

  // --- Thanks Books Logic ---
  bool addThanksBook(String employeeId, ThanksBook newBook) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex != -1) {
      final employee = _employees[employeeIndex];
      if (employee.thanksBooks.any((book) => book.bookNumber == newBook.bookNumber)) {
        return false; // Book number must be unique
      }
      final updatedBooks = List<ThanksBook>.from(employee.thanksBooks)..add(newBook);
      _employees[employeeIndex] = employee.copyWith(thanksBooks: updatedBooks);
      _saveEmployees();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool updateThanksBook(String employeeId, ThanksBook updatedBook) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex != -1) {
      final employee = _employees[employeeIndex];
      final bookIndex = employee.thanksBooks.indexWhere((book) => book.id == updatedBook.id);
      if (bookIndex != -1) {
        if (employee.thanksBooks.any((book) =>
            book.bookNumber == updatedBook.bookNumber && book.id != updatedBook.id)) {
          return false;
        }
        final updatedBooks = List<ThanksBook>.from(employee.thanksBooks);
        updatedBooks[bookIndex] = updatedBook;
        _employees[employeeIndex] = employee.copyWith(thanksBooks: updatedBooks);
        _saveEmployees();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void deleteThanksBook(String employeeId, String bookId) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex != -1) {
      final employee = _employees[employeeIndex];
      final updatedBooks =
          employee.thanksBooks.where((book) => book.id != bookId).toList();
      _employees[employeeIndex] = employee.copyWith(thanksBooks: updatedBooks);
      _saveEmployees();
      notifyListeners();
    }
  }

  // --- Penalty Logic ---
  void addPenalty(String employeeId, Penalty newPenalty) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex != -1) {
      final employee = _employees[employeeIndex];
      final updatedPenalties = List<Penalty>.from(employee.penalties)..add(newPenalty);
      _employees[employeeIndex] = employee.copyWith(penalties: updatedPenalties);
      _saveEmployees();
      notifyListeners();
    }
  }

  void deletePenalty(String employeeId, String penaltyId) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex != -1) {
      final employee = _employees[employeeIndex];
      final updatedPenalties =
          employee.penalties.where((p) => p.id != penaltyId).toList();
      _employees[employeeIndex] = employee.copyWith(penalties: updatedPenalties);
      _saveEmployees();
      notifyListeners();
    }
  }


  // --- Core HR Actions ---
  void grantRaise(String employeeId, DateTime nextRaiseDate) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex == -1) return;

    var employee = _employees[employeeIndex];
    final baseRaiseDate = DateTime(
        employee.effectiveLastRaiseDate.year + 1,
        employee.effectiveLastRaiseDate.month,
        employee.effectiveLastRaiseDate.day);

    final booksToApply = employee.thanksBooks.where((book) {
      return !book.isApplied &&
          !book.bookDate.isBefore(employee.effectiveLastRaiseDate) &&
          book.bookDate.isBefore(baseRaiseDate);
    }).toList();

    final updatedBooks = employee.thanksBooks.map((book) {
      if (booksToApply.any((appliedBook) => appliedBook.id == book.id)) {
        return book.copyWith(isApplied: true);
      }
      return book;
    }).toList();

    var updatedEmployee = employee.copyWith(
      currentSalary: employee.currentSalary + employee.grade.annualRaise,
      effectiveLastRaiseDate: nextRaiseDate,
      raisesReceived: employee.raisesReceived + 1,
      thanksBooks: updatedBooks,
    );

    _employees[employeeIndex] = updatedEmployee;
    _saveEmployees();
    notifyListeners();
  }

  void promoteEmployee(String employeeId, DateTime promotionDate) {
    final employeeIndex = _employees.indexWhere((emp) => emp.id == employeeId);
    if (employeeIndex == -1) return;

    final employee = _employees[employeeIndex];
    final nextGradeIndex =
        gradesData.indexWhere((g) => g.id == employee.grade.id - 1);
    if (nextGradeIndex == -1) return; // Already at highest grade

    final newGrade = gradesData[nextGradeIndex];

    // Consume all unconsumed penalties upon promotion
    final updatedPenalties = employee.penalties.map((penalty) {
      if (!penalty.isConsumed) {
        return penalty.copyWith(isConsumed: true);
      }
      return penalty;
    }).toList();

    // Reset thanks books upon promotion
    final updatedBooks = employee.thanksBooks
        .where((book) => book.isApplied)
        .toList(); // Keep only archived books

    var promotedEmployee = employee.copyWith(
      grade: newGrade,
      currentSalary: newGrade.baseSalary, // Reset to new grade's base salary
      lastPromotionDate: promotionDate,
      effectiveLastRaiseDate: promotionDate, // The clock for raises resets
      raisesReceived: 0, // Reset raise count for the new grade
      thanksBooks: updatedBooks, // Keep history, but they don't affect future raises in new grade
      penalties: updatedPenalties, // Mark penalties as consumed
    );

    _employees[employeeIndex] = promotedEmployee;
    _saveEmployees();
    notifyListeners();
  }
}
