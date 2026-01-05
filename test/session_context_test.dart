import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/models/session_context.dart';
import 'package:pulso_app/services/session_context_service.dart';
import 'package:pulso_app/utils/time_utils.dart';

void main() {
  group('TimeUtils Tests', () {
    test('Morning time detection (5 AM - 11:59 AM)', () {
      final morningTime = DateTime(2026, 1, 5, 8, 30);
      expect(TimeUtils.getTimeOfDay(morningTime), TimeOfDay.morning);
    });

    test('Afternoon time detection (12 PM - 5:59 PM)', () {
      final afternoonTime = DateTime(2026, 1, 5, 14, 30);
      expect(TimeUtils.getTimeOfDay(afternoonTime), TimeOfDay.afternoon);
    });

    test('Evening time detection (6 PM - 4:59 AM)', () {
      final eveningTime = DateTime(2026, 1, 5, 20, 30);
      expect(TimeUtils.getTimeOfDay(eveningTime), TimeOfDay.evening);

      final lateNightTime = DateTime(2026, 1, 5, 2, 30);
      expect(TimeUtils.getTimeOfDay(lateNightTime), TimeOfDay.evening);
    });

    test('ISO 8601 timestamp formatting', () {
      final testTime = DateTime(2026, 1, 5, 12, 36, 34);
      final formatted = TimeUtils.formatTimestamp(testTime);
      expect(formatted, contains('2026-01-05'));
      expect(formatted, contains('12:36:34'));
    });
  });

  group('SessionContext Tests', () {
    test('SessionContext creation with valid data', () {
      final context = SessionContext(
        timestamp: DateTime(2026, 1, 5, 12, 36, 34),
        timeOfDay: TimeOfDay.afternoon,
        stimulants: true,
        nicotine: false,
        activityLevel: ActivityLevel.atRest,
        stressScore: 3,
      );

      expect(context.stimulants, true);
      expect(context.nicotine, false);
      expect(context.activityLevel, ActivityLevel.atRest);
      expect(context.stressScore, 3);
      expect(context.timeOfDay, TimeOfDay.afternoon);
    });

    test('SessionContext JSON serialization', () {
      final context = SessionContext(
        timestamp: DateTime(2026, 1, 5, 12, 36, 34),
        timeOfDay: TimeOfDay.afternoon,
        stimulants: true,
        nicotine: false,
        activityLevel: ActivityLevel.atRest,
        stressScore: 3,
      );

      final json = context.toJson();

      expect(json['time_of_day'], 'Afternoon');
      expect(json['stimulants'], true);
      expect(json['nicotine'], false);
      expect(json['activity_level'], 'At Rest');
      expect(json['stress_score'], 3);
      expect(json['timestamp'], isNotNull);
    });

    test('SessionContext JSON deserialization', () {
      final json = {
        'timestamp': '2026-01-05T12:36:34.000',
        'time_of_day': 'Afternoon',
        'stimulants': true,
        'nicotine': false,
        'activity_level': 'At Rest',
        'stress_score': 3,
      };

      final context = SessionContext.fromJson(json);

      expect(context.timeOfDay, TimeOfDay.afternoon);
      expect(context.stimulants, true);
      expect(context.nicotine, false);
      expect(context.activityLevel, ActivityLevel.atRest);
      expect(context.stressScore, 3);
    });

    test('SessionContext validates stress score range', () {
      expect(
        () => SessionContext(
          timestamp: DateTime.now(),
          timeOfDay: TimeOfDay.afternoon,
          stimulants: false,
          nicotine: false,
          activityLevel: ActivityLevel.atRest,
          stressScore: 0, // Invalid: too low
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => SessionContext(
          timestamp: DateTime.now(),
          timeOfDay: TimeOfDay.afternoon,
          stimulants: false,
          nicotine: false,
          activityLevel: ActivityLevel.atRest,
          stressScore: 6, // Invalid: too high
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('SessionContextService Tests', () {
    test('Create session context with current time', () {
      final context = SessionContextService.createSessionContext(
        stimulants: true,
        nicotine: false,
        activityLevel: ActivityLevel.atRest,
        stressScore: 3,
      );

      expect(context.stimulants, true);
      expect(context.nicotine, false);
      expect(context.activityLevel, ActivityLevel.atRest);
      expect(context.stressScore, 3);
      expect(context.timestamp, isNotNull);
    });

    test('JSON string conversion', () {
      final context = SessionContext(
        timestamp: DateTime(2026, 1, 5, 12, 36, 34),
        timeOfDay: TimeOfDay.afternoon,
        stimulants: true,
        nicotine: false,
        activityLevel: ActivityLevel.atRest,
        stressScore: 3,
      );

      final jsonString = SessionContextService.toJsonString(context);

      expect(jsonString, contains('Afternoon'));
      expect(jsonString, contains('true'));
      expect(jsonString, contains('false'));
      expect(jsonString, contains('At Rest'));
      expect(jsonString, contains('3'));
    });

    test('ECG metadata header preparation', () {
      final context = SessionContext(
        timestamp: DateTime(2026, 1, 5, 12, 36, 34),
        timeOfDay: TimeOfDay.afternoon,
        stimulants: true,
        nicotine: false,
        activityLevel: ActivityLevel.atRest,
        stressScore: 3,
      );

      final header = SessionContextService.prepareECGMetadataHeader(context);

      expect(header, contains('# ECG Session Metadata'));
      expect(header, contains('# End Metadata'));
      expect(header, contains('Afternoon'));
    });

    test('Validate session context', () {
      final validContext = SessionContext(
        timestamp: DateTime.now(),
        timeOfDay: TimeOfDay.afternoon,
        stimulants: true,
        nicotine: false,
        activityLevel: ActivityLevel.atRest,
        stressScore: 3,
      );

      expect(SessionContextService.validateContext(validContext), true);
    });
  });
}
