import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "History",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: 10,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildHistoryItem(context, index);
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, int index) {
    bool isAbnormal = index % 5 == 2; // Mock data logic

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAbnormal ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.monitor_heart,
            color: isAbnormal ? AppColors.error : AppColors.success,
          ),
        ),
        title: Text(
          isAbnormal ? "Irregular Rhythm" : "Normal Sinus Rhythm",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Oct ${12 - index}, 2025 • 30s Recording",
              style: GoogleFonts.outfit(fontSize: 12),
            ),
             if (isAbnormal)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Action Required",
                  style: GoogleFonts.outfit(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: () {
          // Navigate to full report (reuse detailed report for now)
          context.go('/insights/report'); 
        },
      ),
    );
  }
}
