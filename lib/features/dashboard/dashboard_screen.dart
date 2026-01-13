import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/ecg_storage_service.dart';
import '../../models/ecg_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ECGStorageService _storageService = ECGStorageService();
  ECGSession? _lastSession;
  bool _isLoading = true;
  String _authStatus = "Checking...";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Fetch only the latest session
        final sessions = await _storageService.getRecentSessions(
          user.id,
          limit: 1,
        );
        if (mounted) {
          setState(() {
            _lastSession = sessions.isNotEmpty ? sessions.first : null;
            _isLoading = false;
            _authStatus = "Ready";
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _authStatus = "Error loading data";
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _authStatus = "Not Authenticated";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's Status Card
              _buildStatusCard(),
              const SizedBox(height: 16),

              // Live Connection Card
              _buildConnectionCard(context),
              const SizedBox(height: 16),

              // Key Metrics Strip
              _buildMetricsStrip(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                "Quick Actions",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 32),

              // Recent Insights
              Text(
                "Recent Insights",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    // Logic to determine status from last session (mock logic for now if no analysis data in session model)
    // Ideally, ECGSession should have an 'analysisResult' field, but for now we check basic metrics
    String status = "No Data";
    String message = "Start your first recording.";
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;

    if (_isLoading) {
      status = "Loading...";
      message = "Fetching latest data...";
    } else if (_lastSession != null) {
      // Check heart rate status
      final hr = _lastSession!.averageHeartRate ?? 0;

      // If HR is 0 or within normal range (60-100), show stable
      // Also show stable for simulated/estimated values (typically 65-90)
      if (hr == 0 || (hr >= 55 && hr <= 110)) {
        status = "Stable";
        if (hr == 0) {
          message = "Your recent session was recorded.";
        } else {
          message = "Your heart rhythm appears normal.";
        }
        color = AppColors.success; // Assuming green
        icon = Icons.check_circle_outline;
      } else {
        status = "Attention";
        message = "Heart rate outside normal range.";
        color = AppColors.error; // Assuming red/orange
        icon = Icons.warning_amber_rounded;
      }
    }

    return Card(
      color: _lastSession != null ? color : Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(icon, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastSession != null
                  ? "Last Assessment: ${_formatDate(_lastSession!.startTime)}"
                  : "Last Assessment: --",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, can use intl package later
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildConnectionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_searching,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: $_authStatus", // Debug info for user
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  "Pair your ECG device",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/ecg/pairing'),
              child: Text(
                "Connect",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsStrip() {
    // Extract real metrics from latest session
    String bpm = "--";
    String hrv = "--";
    String stress = "--";

    if (_lastSession != null) {
      // Heart Rate
      if (_lastSession!.averageHeartRate != null) {
        bpm = "${_lastSession!.averageHeartRate!.toInt()} bpm";
      }

      // Debug: print R-peaks count
      print('DEBUG Dashboard: R-peaks count = ${_lastSession!.rPeaks.length}');

      // Calculate HRV (SDNN) from R-peaks if available
      if (_lastSession!.rPeaks.length >= 2) {
        final rrIntervals = _lastSession!.rPeaks
            .where((p) => p.rrInterval > 0)
            .map((p) => p.rrInterval)
            .toList();

        if (rrIntervals.length >= 2) {
          // Calculate SDNN (Standard Deviation of NN intervals)
          final meanRR =
              rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
          double sumSquaredDiff = 0;
          for (final rr in rrIntervals) {
            sumSquaredDiff += (rr - meanRR) * (rr - meanRR);
          }
          final sdnn = (sumSquaredDiff / (rrIntervals.length - 1)).abs();
          final sdnnSqrt = (sdnn > 0) ? (sdnn * 1000).toInt() : 0;
          hrv = "$sdnnSqrt ms";

          // Derive stress level from HRV (SDNN)
          // Higher HRV = Lower stress, Lower HRV = Higher stress
          if (sdnnSqrt > 100) {
            stress = "Low";
          } else if (sdnnSqrt > 50) {
            stress = "Moderate";
          } else if (sdnnSqrt > 20) {
            stress = "High";
          } else {
            stress = "Very High";
          }
        }
      } else if (_lastSession!.averageHeartRate != null) {
        // Fallback: Estimate HRV/stress from heart rate if no R-peaks
        final avgHR = _lastSession!.averageHeartRate!;
        // Normal resting HR typically means better HRV
        if (avgHR >= 60 && avgHR <= 80) {
          hrv = "Good";
          stress = "Low";
        } else if (avgHR > 80 && avgHR <= 100) {
          hrv = "Fair";
          stress = "Moderate";
        } else {
          hrv = "Check";
          stress = "High";
        }
      }
    }

    return Row(
      children: [
        Expanded(child: _buildMetricItem("Heart Rate", bpm, Icons.favorite)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricItem("HRV", hrv, Icons.graphic_eq)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricItem("Stress", stress, Icons.sentiment_satisfied),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textLight.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          context,
          "Start ECG",
          Icons.play_arrow,
          AppColors.primary,
          () => context.go('/ecg'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          "Consult AI",
          Icons.auto_awesome,
          AppColors.secondary,
          () => context.push('/chat'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          "History",
          Icons.history,
          AppColors.secondary,
          () => context.go('/history'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentInsights() {
    if (_lastSession == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No recent sessions found",
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.bolt, color: AppColors.primary, size: 20),
        ),
        title: Text(
          "ECG Session #${_lastSession!.id}",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(_lastSession!.startTime),
          style: GoogleFonts.inter(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to insights details
        },
      ),
    );
  }
}
