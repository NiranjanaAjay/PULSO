import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class DetailedReportScreen extends StatelessWidget {
  const DetailedReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text("Detailed Report", style: GoogleFonts.outfit(color: AppColors.textLight)),
        leading: const BackButton(color: AppColors.textLight),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnosis Banner
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(color: AppColors.success),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    "Normal Sinus Rhythm",
                    style: GoogleFonts.outfit(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                   Text(
                    "No irregularities detected",
                    style: GoogleFonts.outfit(color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Findings
            Text(
              "AI Findings",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFindingItem("Heart Rate", "Within normal range (60-100 bpm)"),
            _buildFindingItem("P-Wave", "Present and normal morphology"),
            _buildFindingItem("QRS Complex", "Narrow (< 120ms)"),
            _buildFindingItem("Irregularities", "None detected"),

            const SizedBox(height: 24),

            // Advice
            Text(
              "Contextual Advice",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Based on this recording, your heart rhythm is normal. Continue creating routine checkpoints. If you feel symptoms such as dizziness or palpitations, record a new session immediately.",
                style: GoogleFonts.outfit(fontSize: 14, height: 1.5),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text("Export as PDF"),
                style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFindingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fiber_manual_record, size: 12, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.outfit(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
