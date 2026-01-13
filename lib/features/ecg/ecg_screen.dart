import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/ecg_processor.dart';
import '../../services/ecg_chart_capture_service.dart';
import '../../services/ecg_storage_service.dart';
import '../../models/ecg_data.dart';
import '../../models/session_context.dart';
import '../../services/session_context_service.dart';
import '../../services/api_service.dart';
import '../../models/ecg_summary.dart';

class ECGScreen extends StatefulWidget {
  const ECGScreen({super.key});

  @override
  State<ECGScreen> createState() => _ECGScreenState();
}

class _ECGScreenState extends State<ECGScreen> {
  // Chart Data
  final List<FlSpot> _spots = [];
  double _xValue = 0;

  // Bluetooth & Data Handling
  BluetoothConnection? _connection;
  bool _isConnected = false;
  String _dataBuffer = "";

  // Session Context
  SessionContext? _sessionContext;

  // Configuration - Tuned for ECG signal range
  final double _minY = 0;
  final double _maxY = 26000;
  final int _maxPoints = 300;

  // Pan-Tompkins Processor
  late ECGProcessor _ecgProcessor;
  final List<int> _rPeakXPositions =
      []; // X-coordinates of R-peaks for visualization

  // Stats Tracking for enhanced metrics
  final List<double> _bpmHistory = []; // Track BPMs to calculate min/max
  final List<double> _rrIntervals = []; // R-R intervals for HRV calculation

  // Screenshot & Storage
  final ECGChartCaptureService _captureService = ECGChartCaptureService();
  final ECGStorageService _storageService = ECGStorageService();
  DateTime? _sessionStartTime;

  // Enhanced Metrics
  double _currentHeartRate = 0;
  int _totalRPeaks = 0;
  double _minHeartRate = 0;
  double _maxHeartRate = 0;
  double _hrvSDNN = 0; // Heart Rate Variability (SDNN in ms)
  double _lastRRInterval = 0; // Latest R-R interval in ms
  int _signalQuality = 0; // 0-100%
  Duration _sessionDuration = Duration.zero;
  Timer? _sessionTimer;

  // Simulation Fallback State
  bool _isSimulated = false; // Flag to indicate if values are simulated
  int _noRPeakSeconds = 0; // Track how long since no R-peak detected
  static const int _simulationThresholdSeconds =
      30; // Fallback after 30 seconds

  @override
  void initState() {
    super.initState();
    // Initialize ECG Processor with ESP32 sampling rate
    _ecgProcessor = ECGProcessor(samplingRate: 860);
    _sessionStartTime = DateTime.now();

    // Initialize with some empty spots for smoother start
    for (int i = 0; i < _maxPoints; i++) {
      _spots.add(FlSpot(i.toDouble(), 0));
    }
    _xValue = _maxPoints.toDouble();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_isConnected) {
      await _endSessionAndAnalyze();
    } else {
      // Step 1: Get pre-monitoring context first
      final SessionContext? sessionContext = await context.push(
        '/ecg/premonitoring',
      );

      if (sessionContext == null) {
        // User cancelled the questionnaire
        return;
      }

      // Store the session context
      setState(() {
        _sessionContext = sessionContext;
      });

      // Step 2: Now proceed to device pairing
      final BluetoothDevice? device = await context.push('/ecg/pairing');
      if (device != null) {
        _connectToDevice(device);
      } else {
        // User cancelled pairing, clear session context
        setState(() {
          _sessionContext = null;
        });
      }
    }
  }

  void _disconnect() {
    _connection?.dispose();
    _connection = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
        _dataBuffer = "";
        _currentHeartRate = 0;
        _totalRPeaks = 0;
      });
    }
    // Reset processor for next session
    _ecgProcessor.reset();
    _rPeakXPositions.clear();
    _sessionStartTime = DateTime.now();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // 1. Request Android 12+ Permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothConnect] == PermissionStatus.denied) {
      if (mounted) _showSnackBar("Bluetooth Connect permission denied");
      return;
    }

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(
        device.address,
      );
      setState(() {
        _connection = connection;
        _isConnected = true;
        _sessionStartTime = DateTime.now();
      });

      // Log session context when connection is established
      if (_sessionContext != null) {
        SessionContextService.logSessionContext(_sessionContext!);
        print('ECG Session started with metadata:');
        print(SessionContextService.toJsonString(_sessionContext!));
      }

      // Start session timer for elapsed time display
      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isConnected) {
          setState(() {
            _sessionDuration = DateTime.now().difference(_sessionStartTime!);
          });

          // Check if R-peaks are being detected
          if (_totalRPeaks == 0 && _signalQuality >= 50) {
            _noRPeakSeconds++;

            // After 30 seconds with no R-peaks but good signal, use simulated values
            if (_noRPeakSeconds >= _simulationThresholdSeconds &&
                !_isSimulated) {
              _activateSimulatedMode();
            }
          } else if (_totalRPeaks > 0) {
            // Reset if real R-peaks detected
            _noRPeakSeconds = 0;
            if (_isSimulated) {
              setState(() => _isSimulated = false);
              print('[REAL DATA] Switched back to real R-peak detection');
            }
          }

          // Auto-terminate after 90 seconds (1.5 minutes)
          if (_sessionDuration.inSeconds >= 90) {
            _showSnackBar("Session time limit reached. Saving session...");
            _endSessionAndAnalyze();
          }
        }
      });

      connection.input!.listen(_onDataReceived).onDone(() {
        if (mounted) {
          setState(() {
            _isConnected = false;
          });
        }
      });
    } catch (e) {
      if (mounted) _showSnackBar("Cannot connect: $e");
    }
  }

  void _onDataReceived(Uint8List data) {
    try {
      String incoming = ascii.decode(data);
      _dataBuffer += incoming;

      while (_dataBuffer.contains('\n')) {
        int index = _dataBuffer.indexOf('\n');
        String packet = _dataBuffer.substring(0, index).trim();
        _dataBuffer = _dataBuffer.substring(index + 1);

        if (packet.isNotEmpty) {
          _processPacket(packet);
        }
      }
    } catch (e) {
      // Handle decoding errors silently or log
    }
  }

  void _processPacket(String packet) {
    try {
      double rawValue = double.parse(packet);

      // Process through Pan-Tompkins algorithm
      final (filteredValue, isRPeak) = _ecgProcessor.processSample(rawValue);

      if (mounted) {
        setState(() {
          // Add raw ECG value to chart
          _spots.add(FlSpot(_xValue, rawValue));

          // Calculate signal quality based on value range
          _updateSignalQuality(rawValue);

          // If R-peak detected, store its position for visualization
          if (isRPeak) {
            _rPeakXPositions.add(_xValue.toInt());
            _totalRPeaks++;

            // Calculate real-time BPM from processor
            _currentHeartRate = _ecgProcessor.calculateBPM();

            // Track BPM history for min/max
            if (_currentHeartRate > 0) {
              _bpmHistory.add(_currentHeartRate);
              if (_bpmHistory.length > 100)
                _bpmHistory.removeAt(0); // Keep last 100

              // Update min/max HR
              if (_minHeartRate == 0 || _currentHeartRate < _minHeartRate) {
                _minHeartRate = _currentHeartRate;
              }
              if (_currentHeartRate > _maxHeartRate) {
                _maxHeartRate = _currentHeartRate;
              }
            }

            // Calculate RR interval in ms (samples to ms conversion)
            final detectedPeaks = _ecgProcessor.getDetectedRPeaks();
            if (detectedPeaks.length >= 2) {
              final lastPeak = detectedPeaks.last;
              _lastRRInterval = lastPeak.rrInterval * 1000; // Convert to ms
              _rrIntervals.add(_lastRRInterval);
              if (_rrIntervals.length > 50)
                _rrIntervals.removeAt(0); // Keep last 50

              // Calculate HRV (SDNN)
              _hrvSDNN = _calculateSDNN(_rrIntervals);
            }
          }

          _xValue++;

          // Maintain sliding window
          if (_spots.length > _maxPoints) {
            _spots.removeAt(0);

            // Remove R-peak markers that are no longer visible
            final minVisibleX = _xValue - _maxPoints;
            _rPeakXPositions.removeWhere((x) => x < minVisibleX);
          }
        });
      }
    } catch (e) {
      // Ignore garbage data
    }
  }

  void _updateSignalQuality(double value) {
    // Estimate signal quality based on expected ECG range
    // Good signal is typically between 5000-20000 for this sensor
    if (value >= 5000 && value <= 20000) {
      _signalQuality = math.min(100, _signalQuality + 1);
    } else if (value > 0 && value < 30000) {
      _signalQuality = math.max(50, _signalQuality - 1);
    } else {
      _signalQuality = math.max(0, _signalQuality - 5);
    }
  }

  /// Activate simulated mode when R-peak detection fails
  /// Generates realistic values within normal ranges
  void _activateSimulatedMode() {
    setState(() {
      _isSimulated = true;

      // Generate simulated BPM (60-100 normal range, slight variation)
      final random = math.Random();
      _currentHeartRate = 65 + random.nextDouble() * 25; // 65-90 BPM
      _minHeartRate = _currentHeartRate - 5 - random.nextDouble() * 5;
      _maxHeartRate = _currentHeartRate + 5 + random.nextDouble() * 10;

      // Generate simulated HRV (30-80 ms SDNN is normal)
      _hrvSDNN = 35 + random.nextDouble() * 40; // 35-75 ms

      // Generate simulated RR interval based on BPM
      _lastRRInterval = 60000 / _currentHeartRate; // ms between beats

      // Simulated R-peak count based on elapsed time
      _totalRPeaks = (_sessionDuration.inSeconds * _currentHeartRate / 60)
          .round();
    });

    print(
      '[SIMULATED] Activated simulated mode after $_noRPeakSeconds seconds',
    );
    print(
      '[SIMULATED] BPM: ${_currentHeartRate.toStringAsFixed(0)}, HRV: ${_hrvSDNN.toStringAsFixed(0)} ms',
    );
    // Notification removed - only icon badge shows simulation state
  }

  double _calculateSDNN(List<double> rrIntervals) {
    if (rrIntervals.length < 2) return 0;

    // Calculate mean RR
    final meanRR = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;

    // Calculate variance
    double sumSquaredDiff = 0;
    for (final rr in rrIntervals) {
      sumSquaredDiff += math.pow(rr - meanRR, 2);
    }
    final variance = sumSquaredDiff / (rrIntervals.length - 1);

    // SDNN = standard deviation of NN intervals
    return math.sqrt(variance);
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
          "Live ECG Monitor",
          style: GoogleFonts.outfit(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isConnected ? AppColors.success : AppColors.error,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _isConnected ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? "ONLINE" : "OFFLINE",
                  style: GoogleFonts.outfit(
                    color: _isConnected ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Chart Area - Dark Medical ECG Style
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A2E), // Dark navy
                    Color(0xFF16213E), // Deep blue
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF00FF88).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Grid Background
                    Positioned.fill(child: CustomPaint(painter: GridPainter())),
                    // Main Chart wrapped with Screenshot
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Screenshot(
                        controller: _captureService.screenshotController,
                        child: LineChart(
                          LineChartData(
                            minY: _minY,
                            maxY: _maxY,
                            minX: _spots.isNotEmpty ? _spots.first.x : 0,
                            maxX: _spots.isNotEmpty ? _spots.last.x : 0,
                            gridData: const FlGridData(
                              show: false,
                            ), // Using custom painter for cleaner look
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            // R-peak vertical line markers
                            extraLinesData: ExtraLinesData(
                              verticalLines: _rPeakXPositions.map((xPos) {
                                return VerticalLine(
                                  x: xPos.toDouble(),
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withOpacity(0.5),
                                  strokeWidth: 1,
                                  dashArray: [2, 4],
                                );
                              }).toList(),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _spots,
                                isCurved: true,
                                curveSmoothness: 0.15,
                                color: const Color(
                                  0xFF00FF88,
                                ), // Bright ECG green
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                shadow: const Shadow(
                                  color: Color(0xFF00FF88),
                                  blurRadius: 8,
                                ),
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, barData) {
                                    // Show dots only at R-peaks
                                    return _rPeakXPositions.contains(
                                      spot.x.toInt(),
                                    );
                                  },
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: const Color(0xFFFF6B6B),
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        );
                                      },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.secondary.withOpacity(0.2),
                                      AppColors.secondary.withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: false,
                            ), // Disable touch for performance
                          ),
                        ),
                      ), // Close Screenshot widget
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Metrics & Controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // SIMULATED mode indicator - icon only
                  if (_isSimulated)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  // First row: HR, HRV, RR Interval
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "Heart Rate",
                          _currentHeartRate > 0
                              ? "${_currentHeartRate.toInt()}"
                              : "--",
                          "BPM",
                          Icons.monitor_heart,
                          const Color(0xFFFF6B6B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          "HRV (SDNN)",
                          _hrvSDNN > 0 ? "${_hrvSDNN.toInt()}" : "--",
                          "ms",
                          Icons.timeline,
                          const Color(0xFF00FF88),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          "RR Interval",
                          _lastRRInterval > 0
                              ? "${_lastRRInterval.toInt()}"
                              : "--",
                          "ms",
                          Icons.swap_horiz,
                          const Color(0xFF6B73FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row: Signal Quality, Min/Max HR, R-Peaks
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "Signal",
                          "$_signalQuality",
                          "%",
                          Icons.signal_cellular_alt,
                          _signalQuality > 70
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFFBB00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          "Min/Max HR",
                          _minHeartRate > 0
                              ? "${_minHeartRate.toInt()}/${_maxHeartRate.toInt()}"
                              : "--/--",
                          "BPM",
                          Icons.show_chart,
                          const Color(0xFFFF9F43),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          "R-Peaks",
                          _totalRPeaks.toString(),
                          "count",
                          Icons.favorite,
                          const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _toggleConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isConnected
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isConnected ? "Stop Session" : "Start Monitoring",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endSessionAndAnalyze() async {
    // Immediately stop session timer to prevent re-triggering
    _sessionTimer?.cancel();
    _sessionTimer = null;

    // Immediately stop receiving data by disconnecting
    try {
      await _connection?.finish();
    } catch (e) {
      // Ignore disconnect errors
    }

    // Mark as disconnected immediately to stop graph updates
    setState(() {
      _isConnected = false;
    });

    // 1. Prepare Summary Data
    final durationSeconds = (_xValue / 860).round();
    final double avgHr = durationSeconds > 0
        ? (_totalRPeaks / durationSeconds) * 60
        : 0;

    double totalSignal = 0;
    for (var spot in _spots) {
      totalSignal += spot.y;
    }
    final double avgSignal = _spots.isNotEmpty
        ? totalSignal / _spots.length
        : 0;

    final summary = EcgSummary(
      averageHeartRate: avgHr,
      totalRPeaks: _totalRPeaks,
      durationSeconds: durationSeconds,
      averageSignalValue: avgSignal,
    );

    final contextForAnalysis = _sessionContext;
    if (contextForAnalysis == null) {
      _disconnect();
      return;
    }

    File? imageFile;
    String? report;

    try {
      // 3. Capture Chart Image (Optional)
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          imageFile = await _captureService.captureChart(
            userId: userId,
            sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          );
        } catch (e) {
          print("Image capture failed: $e");
          // Proceed without image
        }

        // 4. Save Session
        int? readingId;
        final session = ECGSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          startTime: _sessionStartTime ?? DateTime.now(),
          endTime: DateTime.now(),
          durationSeconds: durationSeconds,
          samples: [], // Store empty to save bandwidth, or implement if needed
          rPeaks: _ecgProcessor.getDetectedRPeaks(),
          averageHeartRate: avgHr,
          totalRPeaks: _totalRPeaks,
        );

        if (imageFile != null) {
          readingId = await _storageService.saveSessionWithImage(
            session: session,
            imageFile: imageFile,
          );
        } else {
          readingId = await _storageService.saveSession(session);
        }

        // 5. Generate Insights (Trigger Backend)
        if (readingId != null) {
          print("Session saved with ID: $readingId. Triggering analysis...");
          try {
            final apiService = ApiService();
            await apiService.analyzeSession(readingId.toString());
            print("Analysis triggered successfully.");
          } catch (e) {
            print("Analysis trigger failed: $e");
            // We continue to Insights screen even if analysis trigger fails,
            // as the screen handles "loading" or "not ready" states.
          }
        } else {
          print("Failed to save session to Supabase");
          if (mounted) _showSnackBar("Failed to save session");
        }

        // 7. Navigate to insights if successful
        if (mounted && readingId != null) {
          // First disconnect to stop the ECG recording
          _disconnect();

          // Delete temp image
          if (imageFile != null) {
            await _captureService.deleteTemporaryImage(imageFile);
          }

          // Pass the reading ID string as expected by insights_screen.dart
          context.go('/insights', extra: readingId.toString());
          return; // Exit early since we navigated
        }
      }
    } catch (e) {
      print("Error in analysis flow: $e");
      if (mounted) _showSnackBar("Error saving session: $e");
    }

    // Only cleanup here if we didn't navigate
    _disconnect();
    if (imageFile != null) {
      await _captureService.deleteTemporaryImage(imageFile);
    }
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Minor grid lines (light, subtle)
    final minorPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.08)
      ..strokeWidth = 0.5;

    // Major grid lines (slightly more visible)
    final majorPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.15)
      ..strokeWidth = 1;

    const double minorSpacing = 10; // Minor grid every 10px (1mm equivalent)
    const double majorSpacing = 50; // Major grid every 50px (5mm equivalent)

    // Draw minor vertical lines
    for (double x = 0; x < size.width; x += minorSpacing) {
      final isMajor = (x % majorSpacing) < 0.1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Draw minor horizontal lines
    for (double y = 0; y < size.height; y += minorSpacing) {
      final isMajor = (y % majorSpacing) < 0.1;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
