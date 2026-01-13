import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/ecg_data.dart';

/// Service for exporting ECG analysis reports as PDF
class PdfExportService {
  /// Generate PDF document from analysis data
  static Future<pw.Document> generateAnalysisPdf({
    required AnalysisResult analysis,
    String? patientName,
    int? patientAge,
    String? patientGender,
    List<String>? conditions,
    List<String>? medications,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, analysis.createdAt),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Session Information
          _buildSectionTitle('Session Information'),
          _buildInfoRow('Date', dateFormat.format(analysis.createdAt)),
          _buildInfoRow('Analysis ID', '${analysis.analysisId}'),
          _buildInfoRow('Reading ID', '${analysis.readingId}'),
          pw.SizedBox(height: 20),

          // Patient Profile (if available)
          if (patientName != null || patientAge != null) ...[
            _buildSectionTitle('Patient Profile'),
            if (patientName != null) _buildInfoRow('Name', patientName),
            if (patientAge != null) _buildInfoRow('Age', '$patientAge years'),
            if (patientGender != null) _buildInfoRow('Gender', patientGender),
            if (conditions != null && conditions.isNotEmpty)
              _buildInfoRow('Conditions', conditions.join(', ')),
            if (medications != null && medications.isNotEmpty)
              _buildInfoRow('Medications', medications.join(', ')),
            pw.SizedBox(height: 20),
          ],

          // Risk Assessment
          _buildSectionTitle('Risk Assessment'),
          _buildRiskBadge(analysis.riskLevel ?? 'low'),
          _buildInfoRow(
            'Confidence',
            '${(analysis.confidenceScore * 100).toStringAsFixed(0)}%',
          ),
          pw.SizedBox(height: 20),

          // AI Analysis - Prediction
          _buildSectionTitle('AI Analysis'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              analysis.prediction,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.SizedBox(height: 16),

          // What This Means For You
          if (analysis.diagnosisSummary != null &&
              analysis.diagnosisSummary!.isNotEmpty) ...[
            _buildSubSectionTitle('What This Means For You'),
            pw.Text(
              analysis.diagnosisSummary!,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 16),
          ],

          // Detailed Analysis
          if (analysis.detailedAnalysis != null &&
              analysis.detailedAnalysis!.isNotEmpty) ...[
            _buildSubSectionTitle('Detailed Analysis'),
            pw.Text(
              analysis.detailedAnalysis!.replaceAll('**', ''),
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 16),
          ],

          // Clinical Analysis
          if (analysis.clinicalAnalysis != null &&
              analysis.clinicalAnalysis!.isNotEmpty) ...[
            _buildSubSectionTitle('Clinical Notes'),
            pw.Text(
              analysis.clinicalAnalysis!,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 16),
          ],

          // Recommendations
          if (analysis.recommendations != null &&
              analysis.recommendations!.isNotEmpty) ...[
            _buildSectionTitle('Recommendations'),
            ...analysis.recommendations!.asMap().entries.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 20,
                      height: 20,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${entry.key + 1}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        entry.value,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Key Takeaway (Summary)
          if (analysis.summary != null && analysis.summary!.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'KEY TAKEAWAY',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    analysis.summary!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  /// Build PDF header
  static pw.Widget _buildHeader(pw.Context context, DateTime createdAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PULSO',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
              pw.Text(
                'ECG Analysis Report',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Text(
            DateFormat('MMM dd, yyyy').format(createdAt),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Build PDF footer with disclaimer
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '⚠️ DISCLAIMER: This report is for informational purposes only and does not constitute medical advice. '
            'Always consult a qualified healthcare professional for medical concerns.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }

  /// Build section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  /// Build sub-section title
  static pw.Widget _buildSubSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  /// Build info row (label: value)
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  /// Build risk level badge
  static pw.Widget _buildRiskBadge(String riskLevel) {
    PdfColor bgColor;
    PdfColor textColor;

    switch (riskLevel.toLowerCase()) {
      case 'critical':
        bgColor = PdfColors.red100;
        textColor = PdfColors.red900;
        break;
      case 'high':
        bgColor = PdfColors.orange100;
        textColor = PdfColors.orange900;
        break;
      case 'moderate':
        bgColor = PdfColors.yellow100;
        textColor = PdfColors.yellow900;
        break;
      default:
        bgColor = PdfColors.green100;
        textColor = PdfColors.green900;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              'Risk Level:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              riskLevel.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Save PDF to device and return file path
  static Future<String> savePdf(pw.Document pdf, DateTime sessionDate) async {
    final output = await getApplicationDocumentsDirectory();
    final fileName =
        'ECG_Report_${DateFormat('yyyy-MM-dd').format(sessionDate)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Share PDF via system share sheet
  static Future<void> sharePdf(pw.Document pdf, DateTime sessionDate) async {
    final filePath = await savePdf(pdf, sessionDate);
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'My ECG Analysis Report from Pulso',
      subject:
          'ECG Analysis Report - ${DateFormat('MMM dd, yyyy').format(sessionDate)}',
    );
  }

  /// Open print dialog
  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'ECG Analysis Report',
    );
  }
}
