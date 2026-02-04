
import 'package:myapp/grade_model.dart';
import 'package:myapp/thanks_book_model.dart';
import 'package:myapp/penalty_model.dart';

// Represents a custom allowance with a name and percentage.
class CustomAllowance {
  String name;
  double percentage;

  CustomAllowance({required this.name, required this.percentage});

  Map<String, dynamic> toJson() => {
        'name': name,
        'percentage': percentage,
      };

  factory CustomAllowance.fromJson(Map<String, dynamic> json) => CustomAllowance(
        name: json['name'] as String,
        percentage: (json['percentage'] as num).toDouble(),
      );
}

// Represents a custom deduction with a name and a fixed amount.
class CustomDeduction {
  String name;
  double amount;

  CustomDeduction({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
      };

  factory CustomDeduction.fromJson(Map<String, dynamic> json) => CustomDeduction(
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}


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
  final List<Penalty> penalties;
  final List<String> additionalInfo;

  // New fields for detailed salary components
  final double dangerAllowancePercentage;
  final double familyAllowance;
  final List<CustomAllowance> customAllowances;
  final List<CustomDeduction> customDeductions;


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
    this.penalties = const [],
    this.additionalInfo = const [],
    // Initialize new fields
    this.dangerAllowancePercentage = 0.0,
    this.familyAllowance = 0.0,
    this.customAllowances = const [],
    this.customDeductions = const [],
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
    List<Penalty>? penalties,
    List<String>? additionalInfo,
    // Add new fields to copyWith
    double? dangerAllowancePercentage,
    double? familyAllowance,
    List<CustomAllowance>? customAllowances,
    List<CustomDeduction>? customDeductions,
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
      penalties: penalties ?? this.penalties,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      // Assign in copyWith
      dangerAllowancePercentage: dangerAllowancePercentage ?? this.dangerAllowancePercentage,
      familyAllowance: familyAllowance ?? this.familyAllowance,
      customAllowances: customAllowances ?? this.customAllowances,
      customDeductions: customDeductions ?? this.customDeductions,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    var thanksBooksFromJson = json['thanksBooks'] as List<dynamic>?;
    List<ThanksBook> thanksBooksList = thanksBooksFromJson != null
        ? thanksBooksFromJson.map((i) => ThanksBook.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    var penaltiesFromJson = json['penalties'] as List<dynamic>?;
    List<Penalty> penaltiesList = penaltiesFromJson != null
        ? penaltiesFromJson.map((i) => Penalty.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    var additionalInfoFromJson = json['additionalInfo'] as List<dynamic>?;
    List<String> additionalInfoList = additionalInfoFromJson != null
        ? additionalInfoFromJson.map((i) => i.toString()).toList()
        : [];
        
    var customAllowancesFromJson = json['customAllowances'] as List<dynamic>?;
    List<CustomAllowance> customAllowancesList = customAllowancesFromJson != null
        ? customAllowancesFromJson.map((i) => CustomAllowance.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    var customDeductionsFromJson = json['customDeductions'] as List<dynamic>?;
    List<CustomDeduction> customDeductionsList = customDeductionsFromJson != null
        ? customDeductionsFromJson.map((i) => CustomDeduction.fromJson(i as Map<String, dynamic>)).toList()
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
      penalties: penaltiesList, 
      additionalInfo: additionalInfoList,
      // Handle new fields in fromJson
      dangerAllowancePercentage: (json['dangerAllowancePercentage'] as num?)?.toDouble() ?? 0.0,
      familyAllowance: (json['familyAllowance'] as num?)?.toDouble() ?? 0.0,
      customAllowances: customAllowancesList,
      customDeductions: customDeductionsList,
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
      'penalties': penalties.map((penalty) => penalty.toJson()).toList(),
      'additionalInfo': additionalInfo,
       // Handle new fields in toJson
      'dangerAllowancePercentage': dangerAllowancePercentage,
      'familyAllowance': familyAllowance,
      'customAllowances': customAllowances.map((a) => a.toJson()).toList(),
      'customDeductions': customDeductions.map((d) => d.toJson()).toList(),
    };
  }
}
