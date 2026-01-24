import 'package:myapp/grade_model.dart';

// Data based on the official salary scale image provided.
final List<Grade> gradesData = [
  // Top grades
  Grade(id: 1, title: 'الأولى', baseSalary: 910000, annualRaise: 20000, raisesCount: null),
  Grade(id: 2, title: 'الثانية', baseSalary: 723000, annualRaise: 17000, raisesCount: 5),
  Grade(id: 3, title: 'الثالثة', baseSalary: 600000, annualRaise: 10000, raisesCount: 5),
  Grade(id: 4, title: 'الرابعة', baseSalary: 509000, annualRaise: 8000, raisesCount: 5),
  Grade(id: 5, title: 'الخامسة', baseSalary: 429000, annualRaise: 6000, raisesCount: 5),
  
  // Lower grades
  Grade(id: 6, title: 'السادسة', baseSalary: 362000, annualRaise: 6000, raisesCount: 4),
  Grade(id: 7, title: 'السابعة', baseSalary: 296000, annualRaise: 6000, raisesCount: 4),
  Grade(id: 8, title: 'الثامنة', baseSalary: 260000, annualRaise: 3000, raisesCount: 4),
  Grade(id: 9, title: 'التاسعة', baseSalary: 210000, annualRaise: 3000, raisesCount: 4),
  Grade(id: 10, title: 'العاشرة', baseSalary: 170000, annualRaise: 3000, raisesCount: 4),
];
