import 'dart:math';

class QrUtils {
  static String generateUniqueCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'ATTEND-$now-$random';
  }
}
