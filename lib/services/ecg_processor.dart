import 'dart:collection';
import '../models/ecg_data.dart';

/// Implements the Pan-Tompkins algorithm for real-time QRS detection
/// Reference: Pan, J., & Tompkins, W. J. (1985). A real-time QRS detection algorithm.
class ECGProcessor {
  final double samplingRate;

  // Filter buffers
  final Queue<double> _lowPassBuffer = Queue();
  final Queue<double> _highPassBuffer = Queue();
  final Queue<double> _derivativeBuffer = Queue();
  final Queue<double> _integrationBuffer = Queue();

  // Processing state
  int _sampleIndex = 0;
  DateTime? _sessionStartTime;

  // R-peak detection state
  final List<RPeak> _detectedRPeaks = [];
  double _signalPeak = 0;
  double _noisePeak = 0;
  double _thresholdI1 = 0;
  double _thresholdI2 = 0;
  int _lastRPeakIndex = -1000; // Initialize far in the past

  // Configuration
  late final int _refractoryPeriodSamples;
  late final int _integrationWindowSize;
  late final double _learningRate;

  // Recent R-R intervals for BPM calculation
  final Queue<double> _rrIntervals = Queue();
  static const int _maxRRIntervals = 8;

  ECGProcessor({required this.samplingRate}) {
    // Calculate parameters based on sampling rate
    // Reduced refractory period to 250ms for better detection
    _refractoryPeriodSamples = (0.25 * samplingRate)
        .round(); // 250ms refractory period
    _integrationWindowSize = (0.15 * samplingRate)
        .round(); // 150ms integration window
    _learningRate = 0.2; // Higher learning rate for faster adaptation

    // Initialize thresholds
    _thresholdI1 = 0;
    _thresholdI2 = 0;
  }

  // Warmup tracking for initial threshold calibration
  int _warmupSamples = 0;
  double _warmupMaxValue = 0;
  // Increased warmup to 400 samples (~465ms at 860Hz) to allow scaled filters to stabilize
  static const int _warmupPeriod = 400;

  /// Process a single ECG sample through simplified peak detection
  /// Returns the filtered value and whether an R-peak was detected
  (double filteredValue, bool isRPeak) processSample(double rawValue) {
    _sessionStartTime ??= DateTime.now();
    _sampleIndex++;

    // Simple moving average for smoothing (reduces noise)
    _rawBuffer.add(rawValue);
    if (_rawBuffer.length > 5) _rawBuffer.removeFirst();

    double smoothedValue =
        _rawBuffer.reduce((a, b) => a + b) / _rawBuffer.length;

    // Track running statistics for adaptive threshold
    _updateRunningStats(smoothedValue);

    // Check refractory period (minimum time between peaks)
    if (_sampleIndex - _lastRPeakIndex < _refractoryPeriodSamples) {
      return (smoothedValue, false);
    }

    // Simple R-peak detection: look for local maximum above threshold
    bool isRPeak = _detectSimplePeak(smoothedValue, rawValue);

    return (smoothedValue, isRPeak);
  }

  // Buffer for raw signal smoothing
  final Queue<double> _rawBuffer = Queue();

  // Running statistics for adaptive threshold
  double _runningMax = 0;
  double _runningMin = double.infinity;
  double _runningMean = 0;
  int _statsCount = 0;

  void _updateRunningStats(double value) {
    _statsCount++;

    // Update running mean
    _runningMean = _runningMean + (value - _runningMean) / _statsCount;

    // Track max/min with decay for adaptation
    if (value > _runningMax) {
      _runningMax = value;
    } else {
      _runningMax = _runningMax * 0.9999 + value * 0.0001; // Slow decay
    }

    if (value < _runningMin || _runningMin == double.infinity) {
      _runningMin = value;
    } else {
      _runningMin = _runningMin * 0.9999 + value * 0.0001; // Slow decay
    }
  }

  /// Simple peak detection using adaptive threshold
  bool _detectSimplePeak(double smoothedValue, double rawValue) {
    // Need enough samples for statistics
    if (_statsCount < 100) return false;

    // Calculate adaptive threshold: 60% between mean and max
    double signalRange = _runningMax - _runningMin;
    double threshold = _runningMean + (signalRange * 0.4);

    // Check if current value is above threshold
    if (smoothedValue < threshold) return false;

    // Check if it's a local maximum (higher than neighbors)
    if (_rawBuffer.length < 3) return false;

    final list = _rawBuffer.toList();
    bool isLocalMax =
        list[list.length - 1] >= list[list.length - 2] &&
        list[list.length - 2] > list[list.length - 3];

    if (!isLocalMax) return false;

    // Found a peak - register it
    _registerRPeak(smoothedValue, rawValue);
    return true;
  }

  /// Low-pass filter: y[n] = 2*y[n-1] - y[n-2] + x[n] - 2*x[n-d1] + x[n-d2]
  /// Original Pan-Tompkins: d1=6, d2=12 for 200Hz -> Cutoff ~15 Hz
  /// Scaled for 860Hz: d1=26, d2=52 to maintain ~15 Hz cutoff
  double _lowPassFilter(double input) {
    _lowPassBuffer.add(input);

    // Need 53 samples for 860Hz (scaled from 13 at 200Hz)
    if (_lowPassBuffer.length < 53) {
      return input;
    }

    if (_lowPassBuffer.length > 53) {
      _lowPassBuffer.removeFirst();
    }

    final list = _lowPassBuffer.toList();
    // Scaled delays: 6->26, 12->52 for 860Hz
    final output =
        2 * (list.length >= 2 ? list[list.length - 2] : 0) -
        (list.length >= 3 ? list[list.length - 3] : 0) +
        list[list.length - 1] -
        2 * (list.length >= 27 ? list[list.length - 27] : 0) +
        (list.length >= 53 ? list[list.length - 53] : 0);

    return output / 32.0; // Normalize
  }

  /// High-pass filter: y[n] = y[n-1] - x[n]/32 + x[n-d1] - x[n-d2] + x[n-d3]/32
  /// Original Pan-Tompkins: d1=16, d2=17, d3=32 for 200Hz -> Cutoff ~5 Hz
  /// Scaled for 860Hz: d1=69, d2=73, d3=138 to maintain ~5 Hz cutoff
  double _highPassFilter(double input) {
    _highPassBuffer.add(input);

    // Need 139 samples for 860Hz (scaled from 33 at 200Hz)
    if (_highPassBuffer.length < 139) {
      return input;
    }

    if (_highPassBuffer.length > 139) {
      _highPassBuffer.removeFirst();
    }

    final list = _highPassBuffer.toList();
    // Scaled delays: 16->69, 17->73, 32->138 for 860Hz
    final output =
        (list.length >= 2 ? list[list.length - 2] : 0) -
        list[list.length - 1] / 32 +
        (list.length >= 70 ? list[list.length - 70] : 0) -
        (list.length >= 74 ? list[list.length - 74] : 0) +
        (list.length >= 139 ? list[list.length - 139] : 0) / 32;

    return output;
  }

  /// Derivative filter: y[n] = (2*x[n] + x[n-1] - x[n-3] - 2*x[n-4]) / 8
  /// Emphasizes QRS slope information
  double _derivativeFilter(double input) {
    _derivativeBuffer.add(input);

    if (_derivativeBuffer.length < 5) {
      return 0;
    }

    if (_derivativeBuffer.length > 5) {
      _derivativeBuffer.removeFirst();
    }

    final list = _derivativeBuffer.toList();
    final output = (2 * list[4] + list[3] - list[1] - 2 * list[0]) / 8.0;

    return output;
  }

  /// Moving window integration: smooths the squared derivative
  double _movingWindowIntegration(double input) {
    _integrationBuffer.add(input);

    if (_integrationBuffer.length > _integrationWindowSize) {
      _integrationBuffer.removeFirst();
    }

    // Calculate average of window
    double sum = 0;
    for (var value in _integrationBuffer) {
      sum += value;
    }

    return sum / _integrationWindowSize;
  }

  /// Adaptive thresholding and R-peak detection
  bool _detectRPeak(double integratedValue, double rawValue) {
    // Track warmup period to calibrate thresholds
    if (_warmupSamples < _warmupPeriod) {
      _warmupSamples++;
      if (integratedValue > _warmupMaxValue) {
        _warmupMaxValue = integratedValue;
      }
      // Initialize thresholds after warmup
      if (_warmupSamples == _warmupPeriod && _warmupMaxValue > 0) {
        _signalPeak = _warmupMaxValue * 0.8;
        _noisePeak = _warmupMaxValue * 0.2;
        _updateThresholds();
      }
      return false;
    }

    // Check refractory period
    if (_sampleIndex - _lastRPeakIndex < _refractoryPeriodSamples) {
      return false;
    }

    // Fallback threshold initialization if warmup failed
    if (_thresholdI1 == 0) {
      _thresholdI1 = integratedValue * 0.3;
      _thresholdI2 = _thresholdI1 * 0.5;
      return false;
    }

    // Dynamic threshold recalibration if signal changes dramatically
    if (integratedValue > _signalPeak * 3 && _signalPeak > 0) {
      // Signal amplitude changed, recalibrate
      _signalPeak = integratedValue * 0.5;
      _updateThresholds();
    }

    // Missed beat detection: if no R-peak for too long, lower threshold
    final samplesSinceLastPeak = _sampleIndex - _lastRPeakIndex;
    final maxExpectedInterval = (samplingRate * 2).toInt(); // 2 seconds max
    if (samplesSinceLastPeak > maxExpectedInterval && _thresholdI1 > 0) {
      // Lower threshold by 10% to catch weaker peaks
      _thresholdI1 *= 0.9;
      _thresholdI2 *= 0.9;
    }

    // Check if current value exceeds threshold
    if (integratedValue > _thresholdI1) {
      // Potential R-peak detected - check for local maximum
      if (_isLocalMaximum(integratedValue)) {
        _registerRPeak(integratedValue, rawValue);
        return true;
      }
    } else {
      // Update noise peak
      _noisePeak =
          _learningRate * integratedValue + (1 - _learningRate) * _noisePeak;
      _updateThresholds();
    }

    return false;
  }

  /// Check if current sample is a local maximum
  /// Uses a small window to confirm we're at a peak
  bool _isLocalMaximum(double currentValue) {
    if (_integrationBuffer.length < 5) return false;

    final list = _integrationBuffer.toList();
    final current = list[list.length - 1];
    final prev1 = list[list.length - 2];
    final prev2 = list[list.length - 3];

    // Peak should be higher than the previous 2 samples
    // This helps filter out noise spikes
    bool isPeak = current >= prev1 && prev1 > prev2;

    // Additional check: current value should be significantly above the mean
    if (isPeak && _signalPeak > 0) {
      isPeak = current > _signalPeak * 0.4; // At least 40% of signal peak
    }

    return isPeak;
  }

  /// Register a detected R-peak
  void _registerRPeak(double integratedValue, double rawValue) {
    // Update signal peak with learning rate
    _signalPeak =
        _learningRate * integratedValue + (1 - _learningRate) * _signalPeak;
    _updateThresholds();

    // Calculate R-R interval
    double rrInterval = 0;
    double instantaneousBPM = 0;

    if (_detectedRPeaks.isNotEmpty) {
      final lastPeak = _detectedRPeaks.last;
      final samplesSinceLastPeak = _sampleIndex - lastPeak.index;
      rrInterval =
          (samplesSinceLastPeak / samplingRate) * 1000; // Convert to ms

      // Calculate instantaneous BPM
      if (rrInterval > 0) {
        instantaneousBPM = 60000 / rrInterval; // 60000 ms per minute

        // Store R-R interval for average BPM calculation
        _rrIntervals.add(rrInterval);
        if (_rrIntervals.length > _maxRRIntervals) {
          _rrIntervals.removeFirst();
        }
      }
    }

    final timestamp = _sessionStartTime!.add(
      Duration(microseconds: (_sampleIndex / samplingRate * 1000000).round()),
    );

    final rPeak = RPeak(
      index: _sampleIndex,
      timestamp: timestamp,
      rrInterval: rrInterval,
      instantaneousBPM: instantaneousBPM,
      amplitude: rawValue,
    );

    _detectedRPeaks.add(rPeak);
    _lastRPeakIndex = _sampleIndex;
  }

  /// Update adaptive thresholds
  void _updateThresholds() {
    // Reduced threshold multiplier for more sensitive detection
    _thresholdI1 = _noisePeak + 0.25 * (_signalPeak - _noisePeak);
    _thresholdI2 = 0.5 * _thresholdI1;
  }

  /// Calculate current heart rate from recent R-R intervals
  double calculateBPM() {
    if (_rrIntervals.isEmpty) return 0;

    // Average R-R interval
    double avgRRInterval =
        _rrIntervals.reduce((a, b) => a + b) / _rrIntervals.length;

    // Convert to BPM
    double bpm = 60000 / avgRRInterval;

    // Sanity check: clamp BPM to realistic range (30-200 BPM)
    if (bpm < 30) return 30;
    if (bpm > 200) return 200;

    return bpm;
  }

  /// Get all detected R-peaks
  List<RPeak> getDetectedRPeaks() {
    return List.unmodifiable(_detectedRPeaks);
  }

  /// Get the most recent R-peaks (for visualization)
  List<RPeak> getRecentRPeaks(int count) {
    if (_detectedRPeaks.length <= count) {
      return List.unmodifiable(_detectedRPeaks);
    }
    return List.unmodifiable(
      _detectedRPeaks.sublist(_detectedRPeaks.length - count),
    );
  }

  /// Reset the processor for a new session
  void reset() {
    _lowPassBuffer.clear();
    _highPassBuffer.clear();
    _derivativeBuffer.clear();
    _integrationBuffer.clear();
    _detectedRPeaks.clear();
    _rrIntervals.clear();

    _sampleIndex = 0;
    _sessionStartTime = null;
    _signalPeak = 0;
    _noisePeak = 0;
    _thresholdI1 = 0;
    _thresholdI2 = 0;
    _lastRPeakIndex = -1000;
    _warmupSamples = 0;
    _warmupMaxValue = 0;
  }

  /// Get current session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'total_samples': _sampleIndex,
      'total_r_peaks': _detectedRPeaks.length,
      'current_bpm': calculateBPM(),
      'signal_peak': _signalPeak,
      'noise_peak': _noisePeak,
      'threshold': _thresholdI1,
    };
  }
}
