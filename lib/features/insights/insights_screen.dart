import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "AI Insights",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Latest Assessment Card
            _buildLatestAssessment(context),
            const SizedBox(height: 24),
            
            // Recommendations
            Text(
              "Recommendations",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecommendationCard(
              "Reduce Caffeine Intake",
              "We noticed slightly elevated HR variability in the morning. Try limiting coffee after 2 PM.",
              Icons.coffee,
            ),
             _buildRecommendationCard(
              "Sleep Consistency",
              "Your resting HR was higher than usual after irregular sleep schedules.",
              Icons.bedtime,
            ),
            const SizedBox(height: 24),

            // Recent Analyses
             Text(
              "Recent Analysis",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildAnalysisHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestAssessment(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/insights/report'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.2),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: const Text(
                     "New",
                     style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                   ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
             const SizedBox(height: 12),
            Text(
              "Normal Sinus Rhythm",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
             const SizedBox(height: 8),
            Text(
              "Confidence: 98% • Low Risk",
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    desc,
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisHistory(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.description_outlined, color: AppColors.textLight),
            title: Text("Analysis #${100 - index}"),
            subtitle: const Text("Oct 12 • 9:30 AM"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/insights/report'),
          ),
        );
      },
    );
  }
}
