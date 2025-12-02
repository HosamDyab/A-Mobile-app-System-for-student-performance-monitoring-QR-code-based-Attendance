import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserRole = 'userRole';
  static const String _keyUserId = 'userId';
  static const String _keyUserName = 'userName';
  static const String _keyStudentId = 'studentId';
  static const String _keyFacultyId = 'facultyId';
  static const String _keyTAId = 'taId';
  
  // Remember Me keys (role-specific)
  static const String _keyRememberMe = 'rememberMe';
  static const String _keyRememberedEmailStudent = 'rememberedEmail_student';
  static const String _keyRememberedEmailFaculty = 'rememberedEmail_faculty';
  static const String _keyRememberedEmailTA = 'rememberedEmail_ta';

  // Save login session
  static Future<void> saveLoginSession({
    required String email,
    required String role,
    required String userId,
    required String userName,
    String? studentId,
    String? facultyId,
    String? taId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    
    if (studentId != null) await prefs.setString(_keyStudentId, studentId);
    if (facultyId != null) await prefs.setString(_keyFacultyId, facultyId);
    if (taId != null) await prefs.setString(_keyTAId, taId);
    
    print('✅ Login session saved for: $email');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get saved login data
  static Future<Map<String, String?>> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyUserEmail),
      'role': prefs.getString(_keyUserRole),
      'userId': prefs.getString(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'studentId': prefs.getString(_keyStudentId),
      'facultyId': prefs.getString(_keyFacultyId),
      'taId': prefs.getString(_keyTAId),
    };
  }

  // Clear login session (logout)
  static Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ Login session cleared');
  }

  // Save remembered email for a specific role
  static Future<void> saveRememberedEmail({
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, true);
    
    switch (role) {
      case 'student':
        await prefs.setString(_keyRememberedEmailStudent, email);
        break;
      case 'faculty':
        await prefs.setString(_keyRememberedEmailFaculty, email);
        break;
      case 'teacher_assistant':
        await prefs.setString(_keyRememberedEmailTA, email);
        break;
    }
    print('✅ Email saved for role: $role');
  }

  // Get remembered email for a specific role
  static Future<String?> getRememberedEmail(String role) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (role) {
      case 'student':
        return prefs.getString(_keyRememberedEmailStudent);
      case 'faculty':
        return prefs.getString(_keyRememberedEmailFaculty);
      case 'teacher_assistant':
        return prefs.getString(_keyRememberedEmailTA);
      default:
        return null;
    }
  }

  // Clear remembered email for a specific role
  static Future<void> clearRememberedEmail(String role) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (role) {
      case 'student':
        await prefs.remove(_keyRememberedEmailStudent);
        break;
      case 'faculty':
        await prefs.remove(_keyRememberedEmailFaculty);
        break;
      case 'teacher_assistant':
        await prefs.remove(_keyRememberedEmailTA);
        break;
    }
    print('✅ Remembered email cleared for role: $role');
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }
}



