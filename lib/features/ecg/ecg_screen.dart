import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ECGScreen extends StatefulWidget {
  const ECGScreen({super.key});

  @override
  State<ECGScreen> createState() => _ECGScreenState();
}

class _ECGScreenState extends State<ECGScreen> {
  final List<FlSpot> _spots = [];
  Timer? _timer;
  double _xValue = 0;
  bool _isRecording = false;
  bool _isConnected = false; // Mock connection state

  @override
  void initState() {
    super.initState();
    // Initialize with some data
    for (int i = 0; i < 100; i++) {
        _spots.add(FlSpot(i.toDouble(), 0));
    }
    _xValue = 100;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
     if (!_isConnected) {
      context.go('/ecg/pairing');
      return;
    }

    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startSimulation();
    } else {
      _timer?.cancel();
    }
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _xValue += 1;
        // Simulate ECG-ish wave (PQRST-ish)
        double y = 0;
        double cycle = _xValue % 20; 
        
        if (cycle < 2) {
          y = 0.1 * cycle; // P wave
        } else if (cycle < 3) y = 0;
        else if (cycle < 4) y = -0.2; // Q
        else if (cycle < 5) y = 1.0; // R
        else if (cycle < 6) y = -0.4; // S
        else if (cycle < 10) y = 0;
        else if (cycle < 13) y = 0.2; // T
        else y = 0; // Baseline

        // Add noise
        y += (Random().nextDouble() - 0.5) * 0.05;

        _spots.add(FlSpot(_xValue, y));
        if (_spots.length > 100) {
          _spots.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text("Live ECG", style: GoogleFonts.outfit(color: AppColors.textLight)),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? AppColors.success : AppColors.error,
            ),
            onPressed: () async {
               // Mock pairing flow
               final result = await context.push('/ecg/pairing');
               if (result == true) {
                 setState(() => _isConnected = true);
               }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Top Metrics
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Heart Rate", style: GoogleFonts.outfit(color: Colors.grey)),
                    Text(
                      _isRecording ? "72" : "--",
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text("bpm", style: GoogleFonts.outfit(fontSize: 12)),
                  ],
                ),
                 Column(
                  children: [
                    Text("Status", style: GoogleFonts.outfit(color: Colors.grey)),
                    Text(
                       _isRecording ? "Recording" : "Ready",
                      style: GoogleFonts.outfit(
                        fontSize: 18, 
                        fontWeight: FontWeight.w600,
                        color: _isRecording ? AppColors.tertiary : AppColors.success
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Waveform
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.green.withOpacity(0.2), strokeWidth: 1),
                      getDrawingVerticalLine: (value) => FlLine(color: Colors.green.withOpacity(0.2), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: _xValue - 100,
                    maxX: _xValue,
                    minY: -1.0,
                    maxY: 1.5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _spots,
                        isCurved: true,
                        color: AppColors.secondary,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Controls
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 FloatingActionButton.large(
                   heroTag: "ecg_btn",
                   backgroundColor: _isRecording ? AppColors.error : AppColors.success,
                   onPressed: _toggleRecording,
                   child: Icon(
                     _isRecording ? Icons.pause : Icons.play_arrow,
                     color: Colors.white,
                     size: 40,
                   ),
                 ),
                 if (_isRecording) ...[
                   const SizedBox(width: 24),
                   FloatingActionButton.large(
                     heroTag: "ecg_stop_btn",
                     backgroundColor: AppColors.surfaceLight,
                     foregroundColor: AppColors.textLight,
                     onPressed: () {
                       _timer?.cancel();
                       context.push('/ecg/summary'); // Go to summary
                     },
                     child: const Icon(Icons.stop),
                   ),
                 ]
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
