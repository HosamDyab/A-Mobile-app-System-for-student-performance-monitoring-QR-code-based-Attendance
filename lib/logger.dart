import 'package:supabase_flutter/supabase_flutter.dart';

class SystemLogger {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Log a user login event
  static Future<void> logLogin({
    required String userId,
    required String userType, // 'student', 'faculty', 'ta'
    required String userName,
  }) async {
    try {
      await _supabase.from('system_log').insert({
        'log_time': DateTime.now().toIso8601String(),
        'event_type': 'authentication',
        'action': 'login',
        'severity': 'info',
        'entity_type': userType,
        'entity_id': userId,
        'actor_type': userType,
        'actor_id': userId,
        'description': '$userName logged in successfully',
        'details': {
          'user_name': userName,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }
      });

      print('✅ Login logged to system_log');
    } catch (e) {
      print('❌ Failed to log login: $e');
    }
  }

  /// Log a user logout event
  static Future<void> logLogout({
    required String userId,
    required String userType,
    required String userName,
  }) async {
    try {
      await _supabase.from('system_log').insert({
        'log_time': DateTime.now().toIso8601String(),
        'event_type': 'authentication',
        'action': 'logout',
        'severity': 'info',
        'entity_type': userType,
        'entity_id': userId,
        'actor_type': userType,
        'actor_id': userId,
        'description': '$userName logged out',
        'details': {
          'user_name': userName,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        }
      });

      print('✅ Logout logged to system_log');
    } catch (e) {
      print('❌ Failed to log logout: $e');
    }
  }

  /// Log failed login attempt
  static Future<void> logFailedLogin({
    required String userId,
    required String userType,
    String? reason,
  }) async {
    try {
      await _supabase.from('system_log').insert({
        'log_time': DateTime.now().toIso8601String(),
        'event_type': 'authentication',
        'action': 'login_failed',
        'severity': 'warning',
        'entity_type': userType,
        'entity_id': userId,
        'actor_type': userType,
        'actor_id': userId,
        'description': 'Failed login attempt for $userId',
        'details': {
          'user_id': userId,
          'reason': reason ?? 'Invalid credentials',
          'timestamp': DateTime.now().toIso8601String(),
        }
      });

      print('⚠️ Failed login logged');
    } catch (e) {
      print('❌ Failed to log failed login: $e');
    }
  }

  /// Log attendance marking
  static Future<void> logAttendance({
    required String studentId,
    required String courseCode,
    required String action, // 'present', 'absent'
  }) async {
    try {
      await _supabase.from('system_log').insert({
        'log_time': DateTime.now().toIso8601String(),
        'event_type': 'attendance',
        'action': action,
        'severity': 'info',
        'entity_type': 'student',
        'entity_id': studentId,
        'actor_type': 'system',
        'description': 'Attendance marked for $studentId in $courseCode',
        'details': {
          'student_id': studentId,
          'course_code': courseCode,
          'status': action,
          'timestamp': DateTime.now().toIso8601String(),
        }
      });
    } catch (e) {
      print('❌ Failed to log attendance: $e');
    }
  }

  /// Log any custom event
  static Future<void> logEvent({
    required String eventType,
    required String action,
    required String description,
    String severity = 'info',
    String? entityType,
    String? entityId,
    String? actorType,
    String? actorId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _supabase.from('system_log').insert({
        'log_time': DateTime.now().toIso8601String(),
        'event_type': eventType,
        'action': action,
        'severity': severity,
        'entity_type': entityType,
        'entity_id': entityId,
        'actor_type': actorType ?? 'system',
        'actor_id': actorId,
        'description': description,
        'details': details ?? {},
      });
    } catch (e) {
      print('❌ Failed to log event: $e');
    }
  }
}
