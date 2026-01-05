import 'dart:convert';
import 'package:flutter/material.dart' hide TimeOfDay; // <--- ADD THIS HIDE
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/session_context.dart';
import '../../services/session_context_service.dart';
import '../../utils/time_utils.dart'; // This contains your custom TimeOfDay enum

/// Pre-Monitoring Diagnostic Questionnaire Screen
/// Captures patient context before ECG recording sessions
class PreMonitoringQuestionnaireScreen extends StatefulWidget {
  const PreMonitoringQuestionnaireScreen({super.key});

  @override
  State<PreMonitoringQuestionnaireScreen> createState() =>
      _PreMonitoringQuestionnaireScreenState();
}

class _PreMonitoringQuestionnaireScreenState
    extends State<PreMonitoringQuestionnaireScreen> with SingleTickerProviderStateMixin {
  // Form state
  bool? _caffeine;
  bool? _nicotine;
  ActivityLevel? _activityLevel;
  double _stressScore = 3.0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFormComplete {
    return _caffeine != null &&
        _nicotine != null &&
        _activityLevel != null;
  }

  void _submitQuestionnaire() {
    if (!_isFormComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please answer all questions before continuing',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Create session context
    final sessionContext = SessionContextService.createSessionContext(
      stimulants: _caffeine!,
      nicotine: _nicotine!,
      activityLevel: _activityLevel!,
      stressScore: _stressScore.round(),
    );

    // Log for debugging
    SessionContextService.logSessionContext(sessionContext);

    // Return the session context to the calling screen
    context.pop(sessionContext);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeOfDay = TimeUtils.getTimeOfDay(now);
    final greeting = TimeUtils.getGreeting(now);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Pre-Monitoring Assessment',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              _buildHeader(greeting, timeOfDay),
              const SizedBox(height: 32),

              // Introduction
              _buildIntroCard(),
              const SizedBox(height: 24),

              // Question 1: Caffeine
              _buildQuestionCard(
                title: 'Caffeine Consumption',
                question: 'Have you consumed any caffeine (coffee, tea, energy drinks) in the last 2 hours?',
                icon: Icons.local_cafe,
                iconColor: Colors.brown,
                child: _buildYesNoToggle(
                  value: _caffeine,
                  onChanged: (val) => setState(() => _caffeine = val),
                ),
              ),
              const SizedBox(height: 16),

              // Question 2: Nicotine
              _buildQuestionCard(
                title: 'Nicotine Use',
                question: 'Have you smoked or used nicotine products since your last recording?',
                icon: Icons.smoke_free,
                iconColor: Colors.orange,
                child: _buildYesNoToggle(
                  value: _nicotine,
                  onChanged: (val) => setState(() => _nicotine = val),
                ),
              ),
              const SizedBox(height: 16),

              // Question 3: Activity Level
              _buildQuestionCard(
                title: 'Activity Level',
                question: 'Are you currently at rest, or have you just finished physical activity?',
                icon: Icons.directions_run,
                iconColor: Colors.blue,
                child: _buildActivitySelector(),
              ),
              const SizedBox(height: 16),

              // Question 4: Stress Level
              _buildQuestionCard(
                title: 'Stress Assessment',
                question: 'How would you rate your current stress level?',
                icon: Icons.psychology,
                iconColor: Colors.purple,
                child: _buildStressSlider(),
              ),
              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String greeting, TimeOfDay timeOfDay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTimeIcon(timeOfDay),
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  'Current session: ${timeOfDay.label}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeIcon(TimeOfDay timeOfDay) {
  switch (timeOfDay) {
    case TimeOfDay.morning:
      return Icons.wb_sunny;
    case TimeOfDay.afternoon:
      return Icons.wb_cloudy;
    case TimeOfDay.evening:
      return Icons.bedtime;
    default:
      return Icons.access_time; // Fallback icon
  }
}

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Please answer these questions to help us provide accurate ECG analysis. Your responses will be recorded with this session.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.blue[900],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required String title,
    required String question,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildYesNoToggle({
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            label: 'Yes',
            isSelected: value == true,
            onTap: () => onChanged(true),
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildToggleButton(
            label: 'No',
            isSelected: value == false,
            onTap: () => onChanged(false),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySelector() {
    return Column(
      children: [
        _buildActivityOption(
          label: 'At Rest',
          subtitle: 'Relaxed, no recent activity',
          icon: Icons.chair,
          value: ActivityLevel.atRest,
        ),
        const SizedBox(height: 12),
        _buildActivityOption(
          label: 'Post-Activity',
          subtitle: 'Just finished exercising or moving',
          icon: Icons.directions_run,
          value: ActivityLevel.postActivity,
        ),
      ],
    );
  }

  Widget _buildActivityOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required ActivityLevel value,
  }) {
    final isSelected = _activityLevel == value;

    return GestureDetector(
      onTap: () => setState(() => _activityLevel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calm',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Very Stressed',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _getStressColor(_stressScore),
            inactiveTrackColor: Colors.grey[200],
            thumbColor: _getStressColor(_stressScore),
            overlayColor: _getStressColor(_stressScore).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: _stressScore,
            min: 1,
            max: 5,
            divisions: 4,
            label: _stressScore.round().toString(),
            onChanged: (value) => setState(() => _stressScore = value),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: _getStressColor(_stressScore).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStressIcon(_stressScore),
                color: _getStressColor(_stressScore),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Level ${_stressScore.round()}: ${_getStressLabel(_stressScore)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getStressColor(_stressScore),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStressColor(double score) {
    if (score <= 2) return AppColors.success;
    if (score <= 3) return Colors.blue;
    if (score <= 4) return Colors.orange;
    return AppColors.error;
  }

  IconData _getStressIcon(double score) {
    if (score <= 2) return Icons.sentiment_very_satisfied;
    if (score <= 3) return Icons.sentiment_neutral;
    if (score <= 4) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  String _getStressLabel(double score) {
    final rounded = score.round();
    switch (rounded) {
      case 1:
        return 'Very Calm';
      case 2:
        return 'Calm';
      case 3:
        return 'Moderate';
      case 4:
        return 'Stressed';
      case 5:
        return 'Very Stressed';
      default:
        return 'Moderate';
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isFormComplete ? _submitQuestionnaire : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: _isFormComplete ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue to ECG Monitoring',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
