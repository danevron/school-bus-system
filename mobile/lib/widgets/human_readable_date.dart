import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HumanReadableDate extends StatelessWidget {
  final String dateString;
  final TextStyle? style;
  final bool showYear;
  
  const HumanReadableDate({
    super.key,
    required this.dateString,
    this.style,
    this.showYear = false,
  });

  String _formatDate(String dateInput, BuildContext context) {
    try {
      DateTime date;
      
      // Try to parse different date formats
      if (dateInput.contains('/')) {
        // Handle formats like "22/9/2025" or "9/22/2025"
        final parts = dateInput.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          date = DateTime(year, month, day);
        } else {
          throw FormatException('Invalid date format');
        }
      } else if (dateInput.contains('-')) {
        // Handle ISO format like "2025-09-22"
        date = DateTime.parse(dateInput);
      } else {
        // Try to parse as ISO format
        date = DateTime.parse(dateInput);
      }

      // Get current locale from context
      final locale = Localizations.localeOf(context);
      
      // Format based on whether to show year, using the app's locale
      if (showYear) {
        return DateFormat('d MMM yyyy', locale.toString()).format(date);
      } else {
        return DateFormat('d MMM', locale.toString()).format(date);
      }
    } catch (e) {
      // Return original string if parsing fails
      return dateInput;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDate(dateString, context),
      style: style,
    );
  }
}