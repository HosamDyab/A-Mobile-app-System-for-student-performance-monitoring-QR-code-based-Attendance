/// Extracts user information (name, ID, role) from MTI email addresses.
///
/// Each role has a different email format:
/// - Student: `name.id@cs.mti.edu.eg`
/// - Faculty: `drname@cs.mti.edu.eg`
/// - Teaching Assistant: `firstname.lastname@cs.mti.edu.eg`
class UserInfoExtractor {
  /// Extracts student info from email (format: name.id@cs.mti.edu.eg)
  static Map<String, String> extractStudentInfo(String email) {
    final username = email.split('@')[0];
    final parts = username.split('.');
    String name = '';
    String id = '';

    if (parts.length >= 2) {
      name = parts[0];
      id = parts[1];
      name = name[0].toUpperCase() + name.substring(1);
    }

    return {'name': name, 'id': id, 'role': 'student'};
  }

  /// Extracts faculty info from email (format: drname@cs.mti.edu.eg)
  static Map<String, String> extractFacultyInfo(String email) {
    final username = email.split('@')[0];
    String name = username.toLowerCase().startsWith('dr')
        ? username.substring(2)
        : username;
    name = name[0].toUpperCase() + name.substring(1);

    return {'name': 'Dr. $name', 'id': '', 'role': 'faculty'};
  }

  /// Extracts teaching assistant info from email (format: firstname.lastname@cs.mti.edu.eg)
  static Map<String, String> extractTeacherAssistantInfo(String email) {
    final username = email.split('@')[0];
    final parts = username.split('.');
    String firstName = '';
    String lastName = '';

    if (parts.length >= 2) {
      firstName = parts[0][0].toUpperCase() + parts[0].substring(1);
      lastName = parts[1][0].toUpperCase() + parts[1].substring(1);
    }

    return {
      'name': '$firstName $lastName',
      'id': '',
      'role': 'teacher_assistant'
    };
  }

  /// Extracts user info based on the provided role.
  static Map<String, String> extractUserInfo(String email, String role) {
    if (role == 'student') {
      return extractStudentInfo(email);
    } else if (role == 'faculty') {
      return extractFacultyInfo(email);
    } else if (role == 'teacher_assistant') {
      return extractTeacherAssistantInfo(email);
    }

    return {'name': '', 'id': '', 'role': ''};
  }
}
