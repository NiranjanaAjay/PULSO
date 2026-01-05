/// Utility functions for time-related operations in PULSO
library;

enum TimeOfDay {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening');

  const TimeOfDay(this.label);
  final String label;
}

class TimeUtils {
  /// Determines the time of day based on the given DateTime
  /// - Morning: 5:00 AM - 11:59 AM
  /// - Afternoon: 12:00 PM - 5:59 PM
  /// - Evening: 6:00 PM - 4:59 AM
  static TimeOfDay getTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;

    if (hour >= 5 && hour < 12) {
      return TimeOfDay.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeOfDay.afternoon;
    } else {
      return TimeOfDay.evening;
    }
  }

  /// Formats a DateTime to ISO 8601 format with timezone
  static String formatTimestamp(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Gets a user-friendly greeting based on time of day
  static String getGreeting(DateTime dateTime) {
    final timeOfDay = getTimeOfDay(dateTime);
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return 'Good Morning';
      case TimeOfDay.afternoon:
        return 'Good Afternoon';
      case TimeOfDay.evening:
        return 'Good Evening';
    }
  }
}
