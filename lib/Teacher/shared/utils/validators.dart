class Validators {
  static bool isValidGrade(String grade) {
    final trimmed = grade.trim();
    if (trimmed.isEmpty) return false;
    final numeric = double.tryParse(trimmed.replaceAll('%', ''));
    return numeric != null && numeric >= 0 && numeric <= 100;
  }
}