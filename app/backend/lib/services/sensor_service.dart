import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class SensorService {
  // Sensor streams
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _compassSubscription;
  StreamSubscription? _stepSubscription;

  // Current sensor data
  double _heading = 0.0; // Compass heading in degrees (0-360)
  int _stepCount = 0;
  int _initialStepCount = 0;

  // Movement detection only - no position prediction
  bool _isMoving = false;
  double _totalAcceleration = 0.0;
  int _movementCounter = 0; // Count consecutive movement detections
  static const double _movementThreshold =
      1.2; // m/s² - minimum to consider "moving"
  static const int _movementConfirmCount =
      3; // Need 3 consecutive readings to confirm movement

  // Low-pass filter for accelerometer (reduce noise)
  double _filteredAccelX = 0.0;
  double _filteredAccelY = 0.0;
  double _filteredAccelZ = 0.0;
  static const double _filterAlpha = 0.15; // Lower = more filtering

  // Calibration
  bool _isCalibrating = true;
  int _calibrationSamples = 0;
  static const int _calibrationRequired = 20; // 2 seconds of samples
  double _gravityX = 0.0;
  double _gravityY = 0.0;
  double _gravityZ = 9.8;

  // Getters
  double get heading => _heading;
  int get steps => _stepCount - _initialStepCount;
  bool get isMoving => _isMoving;
  bool get isCalibrated => !_isCalibrating;

  // Callbacks
  Function(double)? onHeadingChanged;
  Function(int)? onStepDetected;
  Function(bool)? onMovementChanged;

  Future<bool> checkAndRequestPermissions() async {
    try {
      // Request activity recognition permission for step counter
      final activityStatus = await Permission.activityRecognition.request();
      final sensorsStatus = await Permission.sensors.request();

      return activityStatus.isGranted || sensorsStatus.isGranted;
    } catch (e) {
      print('⚠️ Sensor permission error: $e');
      return false;
    }
  }

  void startSensors() async {
    print('🎯 Starting sensors for movement detection');
    _isCalibrating = true;
    _calibrationSamples = 0;

    // Start compass
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        _heading = event.heading!;
        onHeadingChanged?.call(_heading);
      }
    });

    // Start accelerometer
    _accelerometerSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 100),
        ).listen((AccelerometerEvent event) {
          _processAccelerometer(event);
        });

    // Start step counter
    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (_initialStepCount == 0) {
            _initialStepCount = event.steps;
          }
          _stepCount = event.steps;
          onStepDetected?.call(steps);
        },
        onError: (error) {
          print('⚠️ Step counter error: $error');
        },
      );
    } catch (e) {
      print('⚠️ Pedometer not available: $e');
    }

    print('✅ Sensors active - calibrating...');
  }

  void _processAccelerometer(AccelerometerEvent event) {
    // Apply low-pass filter to reduce noise
    _filteredAccelX =
        _filteredAccelX * (1 - _filterAlpha) + event.x * _filterAlpha;
    _filteredAccelY =
        _filteredAccelY * (1 - _filterAlpha) + event.y * _filterAlpha;
    _filteredAccelZ =
        _filteredAccelZ * (1 - _filterAlpha) + event.z * _filterAlpha;

    // Calibration phase - establish baseline gravity
    if (_isCalibrating) {
      _calibrationSamples++;
      _gravityX =
          (_gravityX * (_calibrationSamples - 1) + _filteredAccelX) /
          _calibrationSamples;
      _gravityY =
          (_gravityY * (_calibrationSamples - 1) + _filteredAccelY) /
          _calibrationSamples;
      _gravityZ =
          (_gravityZ * (_calibrationSamples - 1) + _filteredAccelZ) /
          _calibrationSamples;

      if (_calibrationSamples >= _calibrationRequired) {
        _isCalibrating = false;
        print(
          '✅ Sensor calibration complete - gravity: (${_gravityX.toStringAsFixed(2)}, ${_gravityY.toStringAsFixed(2)}, ${_gravityZ.toStringAsFixed(2)})',
        );
      }
      return;
    }

    // Remove calibrated gravity to get linear acceleration
    final linearAccelX = _filteredAccelX - _gravityX;
    final linearAccelY = _filteredAccelY - _gravityY;
    final linearAccelZ = _filteredAccelZ - _gravityZ;

    // Calculate total linear acceleration
    _totalAcceleration = math.sqrt(
      linearAccelX * linearAccelX +
          linearAccelY * linearAccelY +
          linearAccelZ * linearAccelZ,
    );

    // Detect movement with confirmation (need consistent readings)
    final wasMoving = _isMoving;
    if (_totalAcceleration > _movementThreshold) {
      _movementCounter++;
      if (_movementCounter >= _movementConfirmCount) {
        _isMoving = true;
      }
    } else {
      _movementCounter = 0;
      _isMoving = false;
    }

    // Notify if movement state changed
    if (_isMoving != wasMoving) {
      onMovementChanged?.call(_isMoving);
      print(
        '🚶 Movement detected: $_isMoving (accel: ${_totalAcceleration.toStringAsFixed(2)} m/s²)',
      );
    }
  }

  void stopSensors() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _compassSubscription?.cancel();
    _stepSubscription?.cancel();
    _isCalibrating = true;
    _calibrationSamples = 0;
    _isMoving = false;
    _movementCounter = 0;
    print('🛑 Sensors stopped');
  }

  void dispose() {
    stopSensors();
  }
}
