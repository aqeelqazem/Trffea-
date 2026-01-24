class ThanksBook {
  final String id;
  final String bookNumber;
  final DateTime bookDate;
  final int monthsDeducted;
  final String notes; // New field
  final bool isApplied;

  ThanksBook({
    required this.id,
    required this.bookNumber,
    required this.bookDate,
    this.monthsDeducted = 1,
    this.notes = '', // Default to empty string
    this.isApplied = false,
  });

  ThanksBook copyWith({
    String? id,
    String? bookNumber,
    DateTime? bookDate,
    int? monthsDeducted,
    String? notes,
    bool? isApplied,
  }) {
    return ThanksBook(
      id: id ?? this.id,
      bookNumber: bookNumber ?? this.bookNumber,
      bookDate: bookDate ?? this.bookDate,
      monthsDeducted: monthsDeducted ?? this.monthsDeducted,
      notes: notes ?? this.notes,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  factory ThanksBook.fromJson(Map<String, dynamic> json) {
    return ThanksBook(
      id: json['id'] as String,
      bookNumber: json['bookNumber'] as String,
      bookDate: DateTime.parse(json['bookDate'] as String),
      monthsDeducted: json['monthsDeducted'] as int? ?? 1,
      notes: json['notes'] as String? ?? '', // Handle new field
      isApplied: json['isApplied'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookNumber': bookNumber,
      'bookDate': bookDate.toIso8601String(),
      'monthsDeducted': monthsDeducted,
      'notes': notes, // Handle new field
      'isApplied': isApplied,
    };
  }
}
