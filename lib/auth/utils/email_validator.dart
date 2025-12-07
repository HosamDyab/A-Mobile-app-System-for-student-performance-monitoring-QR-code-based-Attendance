/// Validates MTI email addresses for different user roles.
///
/// Enforces strict email format rules based on whether the user is a student,
/// faculty member, or teaching assistant.
class EmailValidator {
  /// Validates student email format: `name.id@cs.mti.edu.eg`
  static bool isValidStudentEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z]+\.\d+@cs\.mti\.edu\.eg$');
    return regex.hasMatch(email);
  }

  /// Validates faculty email format: `drname@cs.mti.edu.eg`
  static bool isValidFacultyEmail(String email) {
    final regex =
        RegExp(r'^dr[a-zA-Z]+@cs\.mti\.edu\.eg$', caseSensitive: false);
    return regex.hasMatch(email);
  }

  /// Validates teaching assistant email format: `firstname.lastname@cs.mti.edu.eg`
  static bool isValidTeacherAssistantEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z]+\.[a-zA-Z]+@cs\.mti\.edu\.eg$');
    return regex.hasMatch(email);
  }

  /// Validates MTI email based on the provided role.
  ///
  /// Returns `true` if the email matches the role-specific format.
  static bool isValidMTIEmail(String email, String role) {
    if (role == 'student') {
      return isValidStudentEmail(email);
    } else if (role == 'faculty') {
      return isValidFacultyEmail(email);
    } else if (role == 'teacher_assistant') {
      return isValidTeacherAssistantEmail(email);
    }
    return false;
  }
}
