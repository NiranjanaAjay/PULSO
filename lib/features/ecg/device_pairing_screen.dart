import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  bool _isScanning = false;
  List<String> _devices = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });
    
    // Mock Scan Delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _devices = ["Polar H10", "Movesense Medical", "Unknown Device"];
      });
    }
  }

  void _connect(String deviceName) {
    // Mock Connection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connected to $deviceName")),
    );
    context.pop(true); // Return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text("Connect Device", style: GoogleFonts.outfit(color: AppColors.textLight)),
        leading: const BackButton(color: AppColors.textLight),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.bluetooth, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    "Searching for devices...",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Make sure your device is turned on and nearby.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Device List
            Text(
              "Available Devices",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isScanning
                  ? const Center(child: CircularProgressIndicator())
                  : _devices.isEmpty
                      ? Center(child: Text("No devices found", style: GoogleFonts.outfit(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.watch, color: AppColors.textLight),
                                title: Text(
                                  _devices[index],
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _connect(_devices[index]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: const Text("Connect"),
                                ),
                              ),
                            );
                          },
                        ),
            ),
             const SizedBox(height: 16),
             OutlinedButton(
               onPressed: _isScanning ? null : _startScan,
               child: const Text("Scan Again"),
             )
          ],
        ),
      ),
    );
  }
}
