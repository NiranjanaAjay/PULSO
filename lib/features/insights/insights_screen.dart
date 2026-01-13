import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/pdf_export_service.dart';
import '../../models/ecg_data.dart';

/// Export action types
enum ExportAction { save, share, print }

class InsightsScreen extends StatefulWidget {
  final String? readingId;
  const InsightsScreen({super.key, this.readingId});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  AnalysisResult? _analysis;
  String? _error;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  @override
  void didUpdateWidget(InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readingId != widget.readingId) {
      _fetchAnalysis();
    }
  }

  Future<void> _fetchAnalysis() async {
    if (widget.readingId == null) {
      setState(() {
        _isLoading = false;
        _error = "No session selected. Please select a session from History.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysisData = await ApiService().getAnalysis(widget.readingId!);
      final analysis = AnalysisResult.fromJson(analysisData);

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not load analysis. It might not be ready yet.";
          _isLoading = false;
        });
      }
    }
  }

  /// Request analysis for a session that doesn't have one yet
  Future<void> _requestAndFetchAnalysis() async {
    if (widget.readingId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First request analysis
      await ApiService().analyzeSession(widget.readingId!);

      // Wait a moment for analysis to be saved
      await Future.delayed(const Duration(milliseconds: 500));

      // Then fetch the results
      final analysisData = await ApiService().getAnalysis(widget.readingId!);
      final analysis = AnalysisResult.fromJson(analysisData);

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Analysis request failed: $e";
          _isLoading = false;
        });
      }
    }
  }

  /// Show export options bottom sheet
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Report',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              icon: Icons.save_alt,
              title: 'Save as PDF',
              subtitle: 'Save to your device',
              onTap: () {
                Navigator.pop(context);
                _exportPdf(ExportAction.save);
              },
            ),
            _buildExportOption(
              icon: Icons.share,
              title: 'Share Report',
              subtitle: 'Share via WhatsApp, Email, etc.',
              onTap: () {
                Navigator.pop(context);
                _exportPdf(ExportAction.share);
              },
            ),
            _buildExportOption(
              icon: Icons.print,
              title: 'Print',
              subtitle: 'Send to printer',
              onTap: () {
                Navigator.pop(context);
                _exportPdf(ExportAction.print);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }

  /// Export PDF with specified action
  Future<void> _exportPdf(ExportAction action) async {
    if (_analysis == null) return;

    setState(() => _isExporting = true);

    try {
      final pdf = await PdfExportService.generateAnalysisPdf(
        analysis: _analysis!,
      );

      switch (action) {
        case ExportAction.save:
          final path = await PdfExportService.savePdf(
            pdf,
            _analysis!.createdAt,
          );
          _showSnackBar('Report saved to: $path');
          break;
        case ExportAction.share:
          await PdfExportService.sharePdf(pdf, _analysis!.createdAt);
          break;
        case ExportAction.print:
          await PdfExportService.printPdf(pdf);
          break;
      }
    } catch (e) {
      _showSnackBar('Export failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
        actions: [
          // Export/Share button
          if (_analysis != null)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.share, color: Theme.of(context).iconTheme.color),
              onPressed: _isExporting ? null : _showExportOptions,
              tooltip: 'Export Report',
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _fetchAnalysis,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (widget.readingId == null)
                OutlinedButton(
                  onPressed: () => context.go('/history'),
                  child: const Text("Go to History"),
                )
              else ...[
                // Offer to request analysis for sessions without analysis
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _requestAndFetchAnalysis,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? "Analyzing..." : "Request Analysis"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/history'),
                  child: const Text("Back to History"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_analysis == null) {
      return const Center(child: Text("No data available"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Assessment Card (Risk Level & Confidence)
          _buildAssessmentCard(),
          const SizedBox(height: 20),

          // Main Analysis Section - Layman-friendly explanation
          if (_analysis!.diagnosisSummary != null &&
              _analysis!.diagnosisSummary!.isNotEmpty) ...[
            _buildSectionCard(
              title: "What This Means For You",
              icon: Icons.psychology,
              iconColor: const Color(0xFF00B894),
              content: _analysis!.diagnosisSummary!,
            ),
            const SizedBox(height: 16),
          ],

          // Detailed Analysis Section - Structured breakdown
          if (_analysis!.detailedAnalysis != null &&
              _analysis!.detailedAnalysis!.isNotEmpty) ...[
            _buildSectionCard(
              title: "Detailed Analysis",
              icon: Icons.analytics,
              iconColor: const Color(0xFF9B59B6),
              content: _analysis!.detailedAnalysis!,
            ),
            const SizedBox(height: 16),
          ],

          // Clinical Analysis Section - For healthcare providers
          if (_analysis!.clinicalAnalysis != null &&
              _analysis!.clinicalAnalysis!.isNotEmpty) ...[
            _buildSectionCard(
              title: "Clinical Analysis",
              icon: Icons.medical_services,
              iconColor: const Color(0xFF6B73FF),
              content: _analysis!.clinicalAnalysis!,
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations Section
          if (_analysis!.recommendations != null &&
              _analysis!.recommendations!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                          color: const Color(0xFFFF9F43).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFF9F43),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Recommendations",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_analysis!.recommendations!.length, (index) {
                    final rec = _analysis!.recommendations![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Summary Section - One-line takeaway at the end
          if (_analysis!.summary != null && _analysis!.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.summarize,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Key Takeaway",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _analysis!.summary!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.history),
              label: Text(
                "View Session History",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard() {
    final isNormal = _analysis!.prediction.toLowerCase().contains("normal");
    final color = isNormal
        ? AppColors.success
        : AppColors.error; // Or use RiskLevel if available

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNormal
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.orange.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
                child: Text(
                  _analysis!.riskLevel?.toUpperCase() ?? "ANALYSIS",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analysis!.prediction,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Confidence: ${(_analysis!.confidenceScore * 100).toStringAsFixed(0)}%",
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String text) {
    // Split title/desc if formatted like "Title: Desc"
    String title = "Advice";
    String desc = text;
    if (text.contains(":")) {
      final parts = text.split(":");
      title = parts[0].trim();
      desc = parts.sublist(1).join(":").trim();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
}
