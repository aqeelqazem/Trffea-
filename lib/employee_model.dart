
import 'package:myapp/grade_model.dart';
import 'package:myapp/thanks_book_model.dart';
import 'package:myapp/penalty_model.dart'; // Import the new model

class Employee {
  final String id;
  final String name;
  final String jobTitle;
  final String education;
  final Grade grade;
  final int currentSalary;
  final DateTime startDate;
  final DateTime lastPromotionDate;
  final DateTime effectiveLastRaiseDate;
  final int raisesReceived;
  final List<ThanksBook> thanksBooks;
  final List<Penalty> penalties; // Add penalties list

  Employee({
    required this.id,
    required this.name,
    this.jobTitle = '',
    this.education = '',
    required this.grade,
    required this.currentSalary,
    required this.startDate,
    required this.lastPromotionDate,
    required this.effectiveLastRaiseDate,
    required this.raisesReceived,
    this.thanksBooks = const [],
    this.penalties = const [], // Initialize as empty list
  });

  Employee copyWith({
    String? id,
    String? name,
    String? jobTitle,
    String? education,
    Grade? grade,
    int? currentSalary,
    DateTime? startDate,
    DateTime? lastPromotionDate,
    DateTime? effectiveLastRaiseDate,
    int? raisesReceived,
    List<ThanksBook>? thanksBooks,
    List<Penalty>? penalties, // Add to copyWith
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      education: education ?? this.education,
      grade: grade ?? this.grade,
      currentSalary: currentSalary ?? this.currentSalary,
      startDate: startDate ?? this.startDate,
      lastPromotionDate: lastPromotionDate ?? this.lastPromotionDate,
      effectiveLastRaiseDate: effectiveLastRaiseDate ?? this.effectiveLastRaiseDate,
      raisesReceived: raisesReceived ?? this.raisesReceived,
      thanksBooks: thanksBooks ?? this.thanksBooks,
      penalties: penalties ?? this.penalties, // Handle in copyWith
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    var thanksBooksFromJson = json['thanksBooks'] as List<dynamic>?;
    List<ThanksBook> thanksBooksList = thanksBooksFromJson != null
        ? thanksBooksFromJson.map((i) => ThanksBook.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    var penaltiesFromJson = json['penalties'] as List<dynamic>?; // Handle penalties in fromJson
    List<Penalty> penaltiesList = penaltiesFromJson != null
        ? penaltiesFromJson.map((i) => Penalty.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    final grade = Grade.fromJson(json['grade'] as Map<String, dynamic>);
    final raisesReceived = json['raisesReceived'] as int? ?? 0;

    final int currentSalary = json.containsKey('currentSalary')
        ? json['currentSalary'] as int
        : (grade.baseSalary + (raisesReceived * grade.annualRaise));

    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      education: json['education'] as String? ?? '',
      grade: grade,
      currentSalary: currentSalary,
      startDate: DateTime.parse(json['startDate'] as String),
      lastPromotionDate: DateTime.parse(json['lastPromotionDate'] as String),
      effectiveLastRaiseDate: json.containsKey('effectiveLastRaiseDate')
          ? DateTime.parse(json['effectiveLastRaiseDate'] as String)
          : DateTime.parse(json['lastPromotionDate'] as String),
      raisesReceived: raisesReceived,
      thanksBooks: thanksBooksList,
      penalties: penaltiesList, // Assign in constructor
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jobTitle': jobTitle,
      'education': education,
      'grade': grade.toJson(),
      'currentSalary': currentSalary,
      'startDate': startDate.toIso8601String(),
      'lastPromotionDate': lastPromotionDate.toIso8601String(),
      'effectiveLastRaiseDate': effectiveLastRaiseDate.toIso8601String(),
      'raisesReceived': raisesReceived,
      'thanksBooks': thanksBooks.map((book) => book.toJson()).toList(),
      'penalties': penalties.map((penalty) => penalty.toJson()).toList(), // Handle penalties in toJson
    };
  }
}
