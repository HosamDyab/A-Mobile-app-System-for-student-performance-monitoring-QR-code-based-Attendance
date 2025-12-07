import 'package:uuid/uuid.dart';
import 'package:qra/ustils/supabase_manager.dart';

class QRInstanceService {
  final supabase = SupabaseManager.client;
  final uuid = const Uuid();

  /// Create a lecture instance and return the instanceId (QR code data)
  Future<String> createLectureInstance({
    required String lectureOfferingId,
    required DateTime meetingDate,
    required String startTime, // Format: "HH:MM:SS"
    required String endTime, // Format: "HH:MM:SS"
    String? topic,
    int qrValidityHours = 2,
  }) async {
    final instanceId = uuid.v4();
    final qrExpiresAt = DateTime.now().add(Duration(hours: qrValidityHours));

    await supabase.from('LectureInstance').insert({
      'InstanceId': instanceId,
      'LectureOfferingId': lectureOfferingId,
      'MeetingDate': meetingDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'StartTime': startTime,
      'EndTime': endTime,
      'Topic': topic,
      'QRCode': instanceId, // Use instanceId as QR code
      'QRExpiresAt': qrExpiresAt.toIso8601String(),
      'IsCancelled': false,
    });

    return instanceId;
  }

  /// Create a section instance and return the instanceId
  Future<String> createSectionInstance({
    required String sectionOfferingId,
    required DateTime meetingDate,
    required String startTime,
    required String endTime,
    String? topic,
    int qrValidityHours = 2,
  }) async {
    final instanceId = uuid.v4();
    final qrExpiresAt = DateTime.now().add(Duration(hours: qrValidityHours));

    await supabase.from('SectionInstance').insert({
      'InstanceId': instanceId,
      'SectionOfferingId': sectionOfferingId,
      'MeetingDate': meetingDate.toIso8601String().split('T')[0],
      'StartTime': startTime,
      'EndTime': endTime,
      'Topic': topic,
      'QRCode': instanceId,
      'QRExpiresAt': qrExpiresAt.toIso8601String(),
      'IsCancelled': false,
    });

    return instanceId;
  }

  /// Get active lecture instances for a faculty member
  Future<List<Map<String, dynamic>>> getActiveLectureInstances(
      String facultyId) async {
    final now = DateTime.now();

    final response = await supabase
        .from('LectureInstance')
        .select('''
          *,
          LectureOffering:LectureOfferingId (
            *,
            Course:CourseId (
              Code,
              Title
            )
          )
        ''')
        .eq('LectureOffering.FacultyId', facultyId)
        .gte('QRExpiresAt', now.toIso8601String())
        .eq('IsCancelled', false)
        .order('MeetingDate', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Cancel a lecture instance
  Future<void> cancelLectureInstance(String instanceId) async {
    await supabase
        .from('LectureInstance')
        .update({'IsCancelled': true}).eq('InstanceId', instanceId);
  }

  /// Get attendance count for an instance
  Future<int> getAttendanceCount(String instanceId) async {
    final response = await supabase
        .from('LectureQR')
        .select('AttendanceId')
        .eq('InstanceId', instanceId)
        .eq('Status', 'Present');

    return (response as List).length;
  }

  /// Check if QR code is still valid
  Future<bool> isQRCodeValid(String instanceId) async {
    final instance = await supabase
        .from('LectureInstance')
        .select('QRExpiresAt, IsCancelled')
        .eq('InstanceId', instanceId)
        .maybeSingle();

    if (instance == null) {
      // Try section instance
      final sectionInstance = await supabase
          .from('SectionInstance')
          .select('QRExpiresAt, IsCancelled')
          .eq('InstanceId', instanceId)
          .maybeSingle();

      if (sectionInstance == null) return false;

      if (sectionInstance['IsCancelled'] == true) return false;

      final expiresAt = DateTime.parse(sectionInstance['QRExpiresAt']);
      return DateTime.now().isBefore(expiresAt);
    }

    if (instance['IsCancelled'] == true) return false;

    final expiresAt = DateTime.parse(instance['QRExpiresAt']);
    return DateTime.now().isBefore(expiresAt);
  }
}
