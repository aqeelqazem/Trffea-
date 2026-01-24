
import 'package:uuid/uuid.dart';

class Penalty {
  final String id;
  final String title; // User-defined title of the penalty
  final int delayInMonths; // The delay period specified by the user
  final DateTime date; // The date the penalty was issued
  final String notes; // Additional remarks
  final bool isConsumed; // To track if the penalty's effect has been applied to a promotion

  Penalty({
    required this.id,
    required this.title,
    required this.delayInMonths,
    required this.date,
    this.notes = '',
    this.isConsumed = false,
  });

  // A constructor for creating a new penalty with a generated ID
  factory Penalty.createNew({
    required String title,
    required int delayInMonths,
    required DateTime date,
    String notes = '',
  }) {
    return Penalty(
      id: const Uuid().v4(),
      title: title,
      delayInMonths: delayInMonths,
      date: date,
      notes: notes,
      isConsumed: false,
    );
  }

  // fromJson factory
  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      id: json['id'] as String,
      title: json['title'] as String,
      delayInMonths: json['delayInMonths'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String? ?? '',
      isConsumed: json['isConsumed'] as bool? ?? false,
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'delayInMonths': delayInMonths,
      'date': date.toIso8601String(),
      'notes': notes,
      'isConsumed': isConsumed,
    };
  }

  // copyWith method for immutable updates
  Penalty copyWith({
    String? id,
    String? title,
    int? delayInMonths,
    DateTime? date,
    String? notes,
    bool? isConsumed,
  }) {
    return Penalty(
      id: id ?? this.id,
      title: title ?? this.title,
      delayInMonths: delayInMonths ?? this.delayInMonths,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isConsumed: isConsumed ?? this.isConsumed,
    );
  }
}

