/// Utility functions for student-related operations
class StudentUtils {
  /// Extract student name and ID from email
  /// Example: hosam.100308@cs.mti.edu.eg -> name: "Hosam", id: "100308"
  static Map<String, String> extractStudentInfoFromEmail(String email) {
    try {
      // Split email by @ to get the local part
      final localPart = email.split('@').first;

      // Split by dot to get name and ID
      final parts = localPart.split('.');

      if (parts.length >= 2) {
        final name = parts[0];
        final id = parts[1];

        // Capitalize first letter of name
        final capitalizedName = name.isNotEmpty
            ? name[0].toUpperCase() + name.substring(1).toLowerCase()
            : name;

        return {
          'name': capitalizedName,
          'id': id,
        };
      }

      // Fallback: if format doesn't match, return email parts
      return {
        'name': localPart,
        'id': localPart,
      };
    } catch (e) {
      // Fallback on error
      return {
        'name': email.split('@').first,
        'id': email.split('@').first,
      };
    }
  }

  /// Get student ID from email
  static String getStudentIdFromEmail(String email) {
    return extractStudentInfoFromEmail(email)['id'] ?? '';
  }

  /// Get student name from email
  static String getStudentNameFromEmail(String email) {
    return extractStudentInfoFromEmail(email)['name'] ?? '';
  }
}
