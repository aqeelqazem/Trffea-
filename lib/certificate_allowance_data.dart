
// Defines the mapping of education levels to their corresponding allowance percentages.
final Map<String, double> certificateAllowances = {
  'بدون شهادة': 0.0,      // No allowance
  'ابتدائية': 0.05,        // 5%
  'متوسطة': 0.10,         // 10%
  'إعدادية': 0.15,          // 15%
  'دبلوم': 0.25,           // 25%
  'بكالوريوس': 0.45,      // 45%
  'ماجستير': 0.75,        // 75%
  'دكتوراه': 1.00,         // 100%
};

// A list of education levels for use in dropdowns or other UI elements.
const List<String> educationLevels = [
  'بدون شهادة',
  'ابتدائية',
  'متوسطة',
  'إعدادية',
  'دبلوم',
  'بكالوريوس',
  'ماجستير',
  'دكتوراه',
];
