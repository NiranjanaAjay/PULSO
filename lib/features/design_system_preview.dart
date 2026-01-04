import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class DesignSystemPreviewPage extends StatelessWidget {
  const DesignSystemPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Design System Preview"),
        backgroundColor: AppColors.backgroundLight,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Typography (Inter)",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "This is a sample of the body text using the Inter font family. It is clean, modern, and highly legible.",
              style: GoogleFonts.inter(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),

            Text(
              "Buttons",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Primary Button
            ElevatedButton(
              onPressed: () {},
              child: const Text("Primary Action"),
            ),
            const SizedBox(height: 16),
            // Secondary/Outline Button
            OutlinedButton(
              onPressed: () {},
              child: const Text("Secondary Action"),
            ),
            const SizedBox(height: 16),
            // Ghost Button
            TextButton(onPressed: () {}, child: const Text("Ghost Button")),
            const SizedBox(height: 32),

            Text(
              "Cards (Minimal)",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Home Page Card Sample
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Active",
                            style: GoogleFonts.inter(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(Icons.favorite, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Daily Goal Progress",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You have completed 80% of your daily activity goal. Keep it up!",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textLight.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: 0.8,
                      backgroundColor: AppColors.surfaceHighlight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              "Colors Palette",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildColorChip(AppColors.primary, "Primary\n#E66550"),
                _buildColorChip(AppColors.secondary, "Secondary\n#E66853"),
                _buildColorChip(
                  AppColors.surfaceHighlight,
                  "Highlight\n#F5C3BB",
                  textColor: Colors.black,
                ),
                _buildColorChip(AppColors.backgroundDark, "Dark Bg\n#0A0A0A"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(
    Color color,
    String label, {
    Color textColor = Colors.white,
  }) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
