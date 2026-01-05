import 'dart:convert';
import '../models/session_context.dart';
import '../utils/time_utils.dart';

/// Service for managing session context data
/// Handles creation, storage, and attachment of pre-monitoring metadata
class SessionContextService {
  /// Creates a new session context with the provided data
  static SessionContext createSessionContext({
    required bool stimulants,
    required bool nicotine,
    required ActivityLevel activityLevel,
    required int stressScore,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final timeOfDay = TimeUtils.getTimeOfDay(now);

    return SessionContext(
      timestamp: now,
      timeOfDay: timeOfDay,
      stimulants: stimulants,
      nicotine: nicotine,
      activityLevel: activityLevel,
      stressScore: stressScore,
    );
  }

  /// Converts session context to a formatted JSON string
  static String toJsonString(SessionContext context) {
    return jsonEncode(context.toJson());
  }

  /// Logs the session context for debugging purposes
  static void logSessionContext(SessionContext context) {
    print('=== Pre-Monitoring Session Context ===');
    print(toJsonString(context));
    print('======================================');
  }

  /// Prepares metadata string for attachment to ECG stream/file
  /// Returns a formatted header that can be prepended to ECG data
  static String prepareECGMetadataHeader(SessionContext context) {
    final jsonStr = toJsonString(context);
    return '# ECG Session Metadata\n'
        '# $jsonStr\n'
        '# End Metadata\n';
  }

  /// Validates that all required fields are present and valid
  static bool validateContext(SessionContext context) {
    if (context.stressScore < 1 || context.stressScore > 5) {
      return false;
    }
    if (context.timestamp.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return false; // Timestamp shouldn't be in the future
    }
    return true;
  }
}
