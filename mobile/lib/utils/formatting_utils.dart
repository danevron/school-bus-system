class FormattingUtils {
  static String formatTime(String timeString) {
    try {
      if (timeString.isEmpty) return '';
      final timeDateTime = DateTime.parse(timeString).toLocal();
      return '${timeDateTime.hour.toString().padLeft(2, '0')}:${timeDateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }
}