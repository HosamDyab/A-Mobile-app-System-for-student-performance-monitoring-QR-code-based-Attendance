class DateFormatter {
  static String formatAttendanceTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} '
        '${time.hour < 12 ? 'AM' : 'PM'}';
  }
}