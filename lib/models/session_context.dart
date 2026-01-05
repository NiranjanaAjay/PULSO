import '../utils/time_utils.dart';

/// Activity level options for pre-monitoring questionnaire
enum ActivityLevel {
  atRest('At Rest'),
  postActivity('Post-Activity');

  const ActivityLevel(this.label);
  final String label;
}

/// Session context metadata captured before ECG monitoring
/// This data is attached to ECG recordings to improve clinical interpretation
class SessionContext {
  final DateTime timestamp;
  final TimeOfDay timeOfDay;
  final bool stimulants;
  final bool nicotine;
  final ActivityLevel activityLevel;
  final int stressScore;

  SessionContext({
    required this.timestamp,
    required this.timeOfDay,
    required this.stimulants,
    required this.nicotine,
    required this.activityLevel,
    required this.stressScore,
  }) : assert(stressScore >= 1 && stressScore <= 5, 'Stress score must be between 1 and 5');

  /// Converts the session context to a JSON object for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'timestamp': TimeUtils.formatTimestamp(timestamp),
      'time_of_day': timeOfDay.label,
      'stimulants': stimulants,
      'nicotine': nicotine,
      'activity_level': activityLevel.label,
      'stress_score': stressScore,
    };
  }

  /// Creates a SessionContext from JSON data
  factory SessionContext.fromJson(Map<String, dynamic> json) {
    return SessionContext(
      timestamp: DateTime.parse(json['timestamp'] as String),
      timeOfDay: TimeOfDay.values.firstWhere(
        (e) => e.label == json['time_of_day'],
        orElse: () => TimeOfDay.afternoon,
      ),
      stimulants: json['stimulants'] as bool,
      nicotine: json['nicotine'] as bool,
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.label == json['activity_level'],
        orElse: () => ActivityLevel.atRest,
      ),
      stressScore: json['stress_score'] as int,
    );
  }

  @override
  String toString() {
    return 'SessionContext(timestamp: $timestamp, timeOfDay: ${timeOfDay.label}, '
        'stimulants: $stimulants, nicotine: $nicotine, '
        'activityLevel: ${activityLevel.label}, stressScore: $stressScore)';
  }
}
