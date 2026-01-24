
class Grade {
  final int id;
  final String title;
  final int? raisesCount; // Nullable for Grade 1
  final int baseSalary;
  final int annualRaise;

  const Grade({
    required this.id,
    required this.title,
    this.raisesCount,
    required this.baseSalary,
    required this.annualRaise,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as int,
      title: json['title'] as String,
      raisesCount: json['raisesCount'] as int?,
      baseSalary: json['baseSalary'] as int,
      annualRaise: json['annualRaise'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'raisesCount': raisesCount,
      'baseSalary': baseSalary,
      'annualRaise': annualRaise,
    };
  }
}
