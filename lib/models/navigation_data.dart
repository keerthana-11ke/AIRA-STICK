import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';

import 'navigation_location.dart';
import '../services/location_service.dart';
import '../services/smart_stick_service.dart';
import '../services/ble_service.dart';
import '../services/routing_service.dart';
import 'navigation_session.dart';

class DetectedObject {
  final String label;
  final String direction;

  DetectedObject({required this.label, required this.direction});

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      label: json['label'] as String,
      direction: json['direction'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'direction': direction};
}

class NavigationTelemetry {
  final int frontDistanceCm;
  final int pitDistanceCm;
  final bool waterDetected;
  final int batteryPercent;
  final bool isCharging;
  final String currentMode; // "INDOOR" or "OUTDOOR"
  final int sceneScore;
  final String threatLevel; // "LOW", "MEDIUM", "HIGH", "CRITICAL"
  final String lastVoiceSpoken;
  final List<DetectedObject> detectedObjects;
  final double bluetoothStrength; // 0.0 to 1.0
  final DateTime lastUpdated;

  NavigationTelemetry({
    required this.frontDistanceCm,
    required this.pitDistanceCm,
    required this.waterDetected,
    required this.batteryPercent,
    required this.isCharging,
    required this.currentMode,
    required this.sceneScore,
    required this.threatLevel,
    required this.lastVoiceSpoken,
    required this.detectedObjects,
    required this.bluetoothStrength,
    required this.lastUpdated,
  });

  NavigationTelemetry copyWith({
    int? frontDistanceCm,
    int? pitDistanceCm,
    bool? waterDetected,
    int? batteryPercent,
    bool? isCharging,
    String? currentMode,
    int? sceneScore,
    String? threatLevel,
    String? lastVoiceSpoken,
    List<DetectedObject>? detectedObjects,
    double? bluetoothStrength,
    DateTime? lastUpdated,
  }) {
    return NavigationTelemetry(
      frontDistanceCm: frontDistanceCm ?? this.frontDistanceCm,
      pitDistanceCm: pitDistanceCm ?? this.pitDistanceCm,
      waterDetected: waterDetected ?? this.waterDetected,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
      currentMode: currentMode ?? this.currentMode,
      sceneScore: sceneScore ?? this.sceneScore,
      threatLevel: threatLevel ?? this.threatLevel,
      lastVoiceSpoken: lastVoiceSpoken ?? this.lastVoiceSpoken,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      bluetoothStrength: bluetoothStrength ?? this.bluetoothStrength,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class AlertHistoryItem {
  final String id;
  final DateTime timestamp;
  final String title;
  final String description;
  final String priority; // "LOW", "MEDIUM", "HIGH", "CRITICAL"
  final IconData icon;

  AlertHistoryItem({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
  });
}

class DeviceHardwareInfo {
  final bool isEsp32Connected;
  final String firmwareVersion;
  final String bluetoothAddress;
  final int signalStrengthDb; // -100 to -30
  final String batteryHealth; // "Good", "Fair", "Replace"
  final double storageUsedPercent; // 0.0 to 1.0
  final String microSdStatus; // "Mounted", "Not Found", "Error"
  final String dfPlayerStatus; // "Ready", "Offline", "Error"
  final String speakerStatus; // "Connected", "Disconnected"

  DeviceHardwareInfo({
    required this.isEsp32Connected,
    required this.firmwareVersion,
    required this.bluetoothAddress,
    required this.signalStrengthDb,
    required this.batteryHealth,
    required this.storageUsedPercent,
    required this.microSdStatus,
    required this.dfPlayerStatus,
    required this.speakerStatus,
  });
}

class NavigationProvider with ChangeNotifier {
  late NavigationTelemetry _telemetry;
  late DeviceHardwareInfo _hardwareInfo;
  final List<AlertHistoryItem> _alerts = [];
  bool _isSosActive = false;
  Timer? _simulationTimer;
  final Random _random = Random();

  // App Settings
  bool _isDarkTheme = true;
  bool _notificationsEnabled = true;
  String _emergencyContact = "+1 (555) 019-2834";
  String _voiceLanguage = "English (US)";
  double _voiceVolume = 0.8; // 0.0 to 1.0

  final List<NavigationLocation> _savedLocations = [];
  NavigationLocation? _activeDestination;
  List<String> _navigationInstructions = [];
  int _currentInstructionIndex = -1;
  Timer? _navigationTimer;

  // Dynamic Route Tracking Fields
  List<Point<double>> _routePoints = [];
  int _nextPointIndex = 0;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  bool _isRecalculating = false;
  double _distanceRemaining = 0.0;
  double _timeRemaining = 0.0;
  bool _isRouteLoading = false;
  final Set<int> _announcedManeuvers = {};
  DateTime? _lastDestinationSelectionTime;
  Completer<void>? _audioDoneCompleter;

  static final List<NavigationLocation> _defaultLocations = [
    NavigationLocation(
      id: 'railway_station',
      name: 'Railway Station',
      latitude: 13.11028,
      longitude: 80.20917,
    ),
    NavigationLocation(
      id: 'hospital',
      name: 'Hospital',
      latitude: 13.1156,
      longitude: 80.2069,
    ),
    NavigationLocation(
      id: 'library',
      name: 'Library',
      latitude: 13.1034,
      longitude: 80.1785,
    ),
  ];

  NavigationProvider() {
    _loadSavedLocations();

    // Initial Telemetry Setup matching user's realistic dummy data
    _telemetry = NavigationTelemetry(
      frontDistanceCm: 150,
      pitDistanceCm: 150,
      waterDetected: false,
      batteryPercent: 82,
      isCharging: false,
      currentMode: "OUTDOOR",
      sceneScore: 3,
      threatLevel: "LOW",
      lastVoiceSpoken: "System Ready.",
      detectedObjects: [
        DetectedObject(label: "Person", direction: "Left"),
        DetectedObject(label: "Bicycle", direction: "Right"),
      ],
      bluetoothStrength: 0.85,
      lastUpdated: DateTime.now(),
    );

    // Initial Hardware Info
    _hardwareInfo = DeviceHardwareInfo(
      isEsp32Connected: true,
      firmwareVersion: "v1.4.2-alpha",
      bluetoothAddress: "24:0A:C4:8B:58:AA",
      signalStrengthDb: -64,
      batteryHealth: "Good (96% health)",
      storageUsedPercent: 0.28,
      microSdStatus: "Mounted (16GB)",
      dfPlayerStatus: "Ready",
      speakerStatus: "Connected",
    );

    // Prepopulate Alert History
    _alerts.addAll([
      AlertHistoryItem(
        id: "1",
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        title: "Obstacle Detected",
        description: "Person at 45cm on Left",
        priority: "LOW",
        icon: Icons.person_search,
      ),
      AlertHistoryItem(
        id: "2",
        timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
        title: "Water Detected",
        description: "Surface moisture detected ahead",
        priority: "MEDIUM",
        icon: Icons.water_drop,
      ),
      AlertHistoryItem(
        id: "3",
        timestamp: DateTime.now().subtract(const Duration(minutes: 11)),
        title: "Vehicle Approaching",
        description: "Rapidly moving bicycle on Right",
        priority: "HIGH",
        icon: Icons.directions_bike,
      ),
      AlertHistoryItem(
        id: "4",
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        title: "SOS Activated",
        description: "Guardian notified via emergency signal",
        priority: "CRITICAL",
        icon: Icons.sos,
      ),
    ]);

    // Start live simulation updates
    startSimulation();

    // Listen to BleService connection state changes to update hardwareInfo status and rebuild UI
    BleService.instance.connectionState.listen((state) {
      final isConnected = state == BleConnectionState.connected;
      _hardwareInfo = DeviceHardwareInfo(
        isEsp32Connected: isConnected,
        firmwareVersion: _hardwareInfo.firmwareVersion,
        bluetoothAddress: BleService.instance.connectedDevice?.remoteId.str ?? _hardwareInfo.bluetoothAddress,
        signalStrengthDb: isConnected ? -55 : -100,
        batteryHealth: _hardwareInfo.batteryHealth,
        storageUsedPercent: _hardwareInfo.storageUsedPercent,
        microSdStatus: isConnected ? "Mounted (16GB)" : "Offline",
        dfPlayerStatus: isConnected ? "Ready" : "Offline",
        speakerStatus: isConnected ? "Connected" : "Disconnected",
      );

      _telemetry = _telemetry.copyWith(
        bluetoothStrength: isConnected ? 0.90 : 0.0,
        lastUpdated: DateTime.now(),
      );

      if (!isConnected && navigationStatus == 'Navigating') {
        stopNavigation();
        addAlert(
          'Stick Disconnected',
          'Navigation stopped because AIRA-STICK disconnected.',
          'HIGH',
          Icons.bluetooth_disabled,
        );
      }

      notifyListeners();
    });

    // Subscribe to SmartStickService events (mocked until hardware present)
    SmartStickService.instance.events.listen((event) {
      if (event.type == SmartStickEventType.DESTINATION_AUDIO_DONE) {
        print('DESTINATION_AUDIO_DONE received from stick!');
        developer.log('DESTINATION_AUDIO_DONE received from stick!', name: 'Navigation');
        if (_audioDoneCompleter != null && !_audioDoneCompleter!.isCompleted) {
          _audioDoneCompleter!.complete();
        }
      }

      final bool isWithinSelectionGracePeriod = _lastDestinationSelectionTime != null &&
          DateTime.now().difference(_lastDestinationSelectionTime!).inSeconds < 5;

      switch (event.type) {
        case SmartStickEventType.OBSTACLE_DETECTED:
          if (!isWithinSelectionGracePeriod) {
            _telemetry = _telemetry.copyWith(
              lastVoiceSpoken: 'Fast moving object. Please slow down.',
              lastUpdated: DateTime.now(),
            );
            _speak('Fast moving object. Please slow down.');
          }
          addAlert(
            'Obstacle Detected',
            'Fast moving object. Please slow down.',
            'HIGH',
            Icons.warning_amber_rounded,
          );
          break;
        case SmartStickEventType.PIT_DETECTED:
          if (!isWithinSelectionGracePeriod) {
            _telemetry = _telemetry.copyWith(
              lastVoiceSpoken: 'Pit or step ahead. Please be careful.',
              lastUpdated: DateTime.now(),
            );
            _speak('Pit or step ahead. Please be careful.');
          }
          addAlert(
            'Pit Detected',
            'Pit or step ahead. Please be careful.',
            'HIGH',
            Icons.south_rounded,
          );
          break;
        case SmartStickEventType.WATER_DETECTED:
          if (!isWithinSelectionGracePeriod) {
            _telemetry = _telemetry.copyWith(
              waterDetected: true,
              lastVoiceSpoken: 'Water detected ahead.',
              lastUpdated: DateTime.now(),
            );
            _speak('Water detected ahead.');
          } else {
            _telemetry = _telemetry.copyWith(
              waterDetected: true,
              lastUpdated: DateTime.now(),
            );
          }
          addAlert(
            'Water Detected',
            'Water detected ahead.',
            'MEDIUM',
            Icons.water_drop,
          );
          break;
        case SmartStickEventType.SOS_TRIGGERED:
          _isSosActive = true;
          _telemetry = _telemetry.copyWith(
            threatLevel: 'CRITICAL',
            lastVoiceSpoken: 'SOS activated.',
            lastUpdated: DateTime.now(),
          );
          _speak('SOS activated.');
          addAlert('SOS Triggered', 'SOS activated.', 'CRITICAL', Icons.sos);
          break;
        case SmartStickEventType.COMMAND_SENT:
          // Handle successful command sent to device
          _telemetry = _telemetry.copyWith(lastUpdated: DateTime.now());
          break;
        case SmartStickEventType.COMMAND_FAILED:
          // Handle failed command
          addAlert(
            'Command Failed',
            'Failed to send command to Smart Stick.',
            'HIGH',
            Icons.error_outline,
          );
          break;
        case SmartStickEventType.DISCONNECTED:
          // Handle device disconnected
          addAlert(
            'Device Disconnected',
            'Smart Stick connection lost.',
            'HIGH',
            Icons.bluetooth_disabled,
          );
          break;
        case SmartStickEventType.TELEMETRY_UPDATED:
          // Update telemetry with real data!
          final front = event.frontDistanceCm;
          final pit = event.pitDistanceCm;
          final water = event.waterDetected;

          String threat = _telemetry.threatLevel;
          String voice = _telemetry.lastVoiceSpoken;
          IconData alertIcon = Icons.info_outline;

          if (front != null && front < 50) {
            threat = "HIGH";
            if (!isWithinSelectionGracePeriod) {
              voice = "Obstacle Ahead. Stop.";
              _speak(voice);
            }
            alertIcon = Icons.warning_amber_rounded;
            addAlert(
              "Obstacle Ahead",
              "Front collision pathway blocked at ${front}cm",
              "HIGH",
              alertIcon,
            );
          } else if (pit != null && pit < 100) {
            threat = "MEDIUM";
            if (!isWithinSelectionGracePeriod) {
              voice = "Pit Ahead. Watch step.";
              _speak(voice);
            }
            alertIcon = Icons.analytics_outlined;
            addAlert(
              "Drop-off Detected",
              "Pit/Stairs detected at ${pit}cm",
              "MEDIUM",
              alertIcon,
            );
          } else if (water == true) {
            threat = "MEDIUM";
            if (!isWithinSelectionGracePeriod) {
              voice = "Water Detected. Change path.";
              _speak(voice);
            }
            alertIcon = Icons.water_drop;
            addAlert(
              "Water Detected",
              "Liquid surface detected on pathway",
              "MEDIUM",
              alertIcon,
            );
          } else {
            threat = "LOW";
            if (navigationStatus == 'Navigating') {
              voice = currentInstruction;
            }
          }

          _telemetry = _telemetry.copyWith(
            frontDistanceCm: front ?? _telemetry.frontDistanceCm,
            pitDistanceCm: pit ?? _telemetry.pitDistanceCm,
            waterDetected: water ?? _telemetry.waterDetected,
            threatLevel: threat,
            lastVoiceSpoken: voice,
            lastUpdated: DateTime.now(),
          );
          break;
        case SmartStickEventType.DESTINATION_AUDIO_DONE:
          break;
      }

      notifyListeners();
    });
  }

  // Getters
  NavigationTelemetry get telemetry => _telemetry;
  DeviceHardwareInfo get hardwareInfo => _hardwareInfo;
  List<AlertHistoryItem> get alerts => List.unmodifiable(_alerts);
  bool get isSosActive => _isSosActive;
  bool get isDarkTheme => _isDarkTheme;
  bool get notificationsEnabled => _notificationsEnabled;
  String get emergencyContact => _emergencyContact;
  String get voiceLanguage => _voiceLanguage;
  double get voiceVolume => _voiceVolume;
  List<NavigationLocation> get savedLocations =>
      List.unmodifiable(_savedLocations);
  NavigationLocation? get activeDestination => _activeDestination;
  List<String> get navigationInstructions =>
      List.unmodifiable(_navigationInstructions);

  double get currentLatitude => _currentLatitude == 0.0 ? 12.9606322 : _currentLatitude;
  double get currentLongitude => _currentLongitude == 0.0 ? 77.5716324 : _currentLongitude;
  List<Point<double>> get routePoints => _routePoints;
  double get distanceRemaining => _distanceRemaining;
  double get timeRemaining => _timeRemaining;
  bool get isRecalculating => _isRecalculating;
  bool get isRouteLoading => _isRouteLoading;

  // Toggle Theme
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  // Set Theme Mode
  void setDarkTheme(bool val) {
    _isDarkTheme = val;
    notifyListeners();
  }

  // Set Notifications
  void setNotificationsEnabled(bool val) {
    _notificationsEnabled = val;
    notifyListeners();
  }

  // Set Voice Volume
  void setVoiceVolume(double val) {
    _voiceVolume = val;
    notifyListeners();
  }

  // Set Voice Language
  void setVoiceLanguage(String val) {
    _voiceLanguage = val;
    notifyListeners();
  }

  // Set Emergency Contact
  void updateEmergencyContact(String val) {
    _emergencyContact = val;
    notifyListeners();
  }

  // Saved Locations Persistence
  static const String _locationsStorageKey = 'saved_predefined_locations';

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_locationsStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final saved = NavigationLocation.decodeList(raw);
        _savedLocations.clear();
        _savedLocations.addAll(saved);

        // Update default locations with new coordinates if IDs match, or add them if missing
        for (final defLoc in _defaultLocations) {
          final idx = _savedLocations.indexWhere((loc) => loc.id == defLoc.id);
          if (idx != -1) {
            _savedLocations[idx] = defLoc;
          } else {
            _savedLocations.add(defLoc);
          }
        }
        
        // Remove old default locations that are not in _defaultLocations
        _savedLocations.removeWhere((loc) => !_defaultLocations.any((def) => def.id == loc.id));

      } catch (_) {
        _savedLocations.clear();
        _savedLocations.addAll(_defaultLocations);
      }
    } else {
      _savedLocations.clear();
      _savedLocations.addAll(_defaultLocations);
    }
    notifyListeners();
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonText = NavigationLocation.encodeList(_savedLocations);
    await prefs.setString(_locationsStorageKey, jsonText);
  }

  Future<void> addLocation(NavigationLocation location) async {
    _savedLocations.add(location);
    await _saveLocations();
    notifyListeners();
  }

  Future<void> updateLocation(NavigationLocation location) async {
    final index = _savedLocations.indexWhere((item) => item.id == location.id);
    if (index >= 0) {
      _savedLocations[index] = location;
      await _saveLocations();
      notifyListeners();
    }
  }

  Future<void> deleteLocation(String id) async {
    _savedLocations.removeWhere((item) => item.id == id);
    await _saveLocations();
    notifyListeners();
  }

  Future<void> selectLocationById(String id) async {
    final location = _savedLocations.firstWhere(
      (item) => item.id == id,
      orElse: () => _defaultLocations.firstWhere(
        (item) => item.id == id,
        orElse: () => throw Exception('Location not found with ID: $id'),
      ),
    );
    await _startNavigationToLocation(location);
  }

  Future<bool> processVoiceCommand(String commandText) async {
    final normalized = commandText.toLowerCase();
    for (final location in _savedLocations) {
      final nameLower = location.name.toLowerCase();
      if (normalized.contains(nameLower) && !normalized.contains('nearest')) {
        await _startNavigationToLocation(location);
        return true;
      }
    }

    final keyword = 'railway station';
    if (normalized.contains(keyword) ||
        normalized.contains('nearest station') ||
        normalized.contains('near me')) {
      final nearest = await _findNearestLocationByKeyword(keyword);
      if (nearest != null) {
        await _startNavigationToLocation(nearest);
        return true;
      }
    }

    return false;
  }

  Future<NavigationLocation?> _findNearestLocationByKeyword(
    String keyword,
  ) async {
    try {
      final currentPosition = await LocationService.getCurrentPosition();
      final matches = _savedLocations
          .where(
            (item) => item.name.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();

      if (matches.isEmpty) {
        return null;
      }

      matches.sort((a, b) {
        final da = LocationService.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          a.latitude,
          a.longitude,
        );
        final db = LocationService.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          b.latitude,
          b.longitude,
        );
        return da.compareTo(db);
      });

      return matches.first;
    } catch (_) {
      return null;
    }
  }

  Future<bool> navigateToNearestRailwayStation() async {
    final nearest = await _findNearestLocationByKeyword('railway station');
    if (nearest == null) {
      return false;
    }
    await _startNavigationToLocation(nearest);
    return true;
  }

  Future<void> _startNavigationToLocation(NavigationLocation location) async {
    if (_isRouteLoading) {
      print('ROUTE REQUEST IGNORED: Another request is already in progress.');
      return;
    }

    _isRouteLoading = true;

    // Immediately cancel and reset old navigation state to prevent stale turn commands
    print('DESTINATION CLICKED: ${location.name}');
    developer.log('DESTINATION CLICKED: ${location.name}', name: 'Navigation');
    print('RESETTING PREVIOUS NAVIGATION STATE');
    developer.log('RESETTING PREVIOUS NAVIGATION STATE', name: 'Navigation');

    _navigationTimer?.cancel();
    _navigationTimer = null;
    _routePoints = [];
    _navigationInstructions = [];
    _currentInstructionIndex = -1;
    _nextPointIndex = 1;
    _announcedManeuvers.clear();

    // Immediately register active destination and announce selection voice synchronously (before GPS or route fetch!)
    _activeDestination = location;
    _lastDestinationSelectionTime = DateTime.now();

    _telemetry = _telemetry.copyWith(
      lastVoiceSpoken: '${location.name} selected. Starting navigation.',
      lastUpdated: DateTime.now(),
    );
    _speak('${location.name} selected. Starting navigation.');
    notifyListeners();

    try {
      // Map the selected destination to its specific BLE command
      String destCommand = 'DESTINATION_SELECTED';
      final nameLower = location.name.toLowerCase();
      if (nameLower.contains('railway station')) {
        destCommand = 'DEST_RAILWAY';
      } else if (nameLower.contains('library')) {
        destCommand = 'DEST_LIBRARY';
      } else if (nameLower.contains('hospital')) {
        destCommand = 'DEST_HOSPITAL';
      }

      // Send the mapped destination command immediately so the ESP32 DFPlayer starts speaking
      final success = await SmartStickService.instance.sendNavigationCommand(destCommand);
      if (success) {
        print('BLE COMMAND SENT: $destCommand');
        developer.log('BLE COMMAND SENT: $destCommand', name: 'Navigation');
      }

      print('WAITING FOR ESP32 NAVIGATION START');
      developer.log('WAITING FOR ESP32 NAVIGATION START', name: 'Navigation');

      // Wait for the ESP32 BLE notification: DESTINATION_AUDIO_DONE
      _audioDoneCompleter = Completer<void>();

      if (!BleService.instance.isConnected) {
        // Simulation mode: automatically trigger mock event after 4 seconds to let testing proceed
        Timer(const Duration(seconds: 4), () {
          if (_audioDoneCompleter != null && !_audioDoneCompleter!.isCompleted) {
            SmartStickService.instance.emitMockEvent(
              SmartStickEventType.DESTINATION_AUDIO_DONE,
              'DESTINATION_AUDIO_DONE simulated',
            );
          }
        });
      }

      try {
        await _audioDoneCompleter!.future.timeout(const Duration(seconds: 12));
      } catch (e) {
        print('Timeout waiting for DESTINATION_AUDIO_DONE, proceeding.');
        developer.log('Timeout waiting for DESTINATION_AUDIO_DONE, proceeding.', name: 'Navigation');
      } finally {
        _audioDoneCompleter = null;
      }

      print('NAVIGATION STARTED');
      developer.log('NAVIGATION STARTED', name: 'Navigation');
      print('STARTING NEW GPS ROUTE');
      developer.log('STARTING NEW GPS ROUTE', name: 'Navigation');

      print('GPS NAVIGATION STARTED');
      developer.log('GPS NAVIGATION STARTED', name: 'Navigation');

      // Get user's current GPS coordinates (throw if unavailable, fallback to default for browser safety!)
      Position pos;
      try {
        pos = await LocationService.getCurrentPosition();
      } catch (e) {
        print('GPS permission/acquisition failed: $e. Falling back to default mock location.');
        developer.log('GPS permission/acquisition failed: $e. Falling back to default mock location.', name: 'Navigation');
        pos = Position(
          latitude: 13.1158,
          longitude: 80.2078,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      _currentInstructionIndex = 0;
      _isRecalculating = false;
      _announcedManeuvers.clear();

      _currentLatitude = pos.latitude;
      _currentLongitude = pos.longitude;

      print('SELECTED DESTINATION: ${location.name}');
      developer.log('SELECTED DESTINATION: ${location.name}', name: 'Navigation');
      print('DESTINATION LAT: ${location.latitude}');
      developer.log('DESTINATION LAT: ${location.latitude}', name: 'Navigation');
      print('DESTINATION LNG: ${location.longitude}');
      developer.log('DESTINATION LNG: ${location.longitude}', name: 'Navigation');

      print('CURRENT GPS:');
      print('LAT: $_currentLatitude');
      print('LNG: $_currentLongitude');
      developer.log('CURRENT GPS:\nLAT: $_currentLatitude\nLNG: $_currentLongitude', name: 'Navigation');

      print('STARTING OSRM ROUTE');
      developer.log('STARTING OSRM ROUTE', name: 'Navigation');

      // Try to fetch actual road route using OSRM RoutingService
      final roadSteps = await RoutingService.fetchRoute(
        startLat: _currentLatitude,
        startLon: _currentLongitude,
        endLat: location.latitude,
        endLon: location.longitude,
        destinationName: location.name,
      );

      if (roadSteps == null || roadSteps.isEmpty) {
        print('OSRM ROUTE FAILED');
        developer.log('OSRM ROUTE FAILED', name: 'Navigation');
        throw Exception('OSRM route calculation failed. Unable to generate turn-by-turn directions.');
      }

      _routePoints = roadSteps.map((s) => Point(s.latitude, s.longitude)).toList();
      _navigationInstructions = roadSteps.map((s) => s.instruction).toList();
      print('OSRM ROUTE SUCCESS');
      developer.log('OSRM ROUTE SUCCESS', name: 'Navigation');

      if (_routePoints.isEmpty) {
        print('ROUTE UNAVAILABLE');
        developer.log('ROUTE UNAVAILABLE', name: 'Navigation');
      }

      _nextPointIndex = 1;

      notifyListeners();

      addAlert(
        'Destination Selected',
        '${location.name} selected for navigation',
        'LOW',
        Icons.navigation,
      );

      final initialPos = pos;

      _navigationTimer?.cancel();
      _navigationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        if (_nextPointIndex >= _routePoints.length) {
          timer.cancel();
          _navigationTimer = null;
          _currentInstructionIndex = -1;
          notifyListeners();
          return;
        }

        // Check distance to next waypoint
        final target = _routePoints[_nextPointIndex];
        final dist = LocationService.distanceBetween(
          _currentLatitude, _currentLongitude,
          target.x, target.y,
        );

        // Required Structured Logs on every tick
        print('CURRENT LOCATION: $_currentLatitude, $_currentLongitude');
        developer.log('CURRENT LOCATION: $_currentLatitude, $_currentLongitude', name: 'Navigation');

        if (_nextPointIndex < _routePoints.length) {
          final nextInstr = _navigationInstructions[_nextPointIndex];
          final nextManeuverCmd = _commandFromInstruction(nextInstr);
          String nextManeuverLog = 'STRAIGHT';
          if (nextManeuverCmd == 'TURN_LEFT') nextManeuverLog = 'LEFT';
          if (nextManeuverCmd == 'TURN_RIGHT') nextManeuverLog = 'RIGHT';

          print('NEXT MANEUVER: $nextManeuverLog');
          developer.log('NEXT MANEUVER: $nextManeuverLog', name: 'Navigation');
          print('DISTANCE TO MANEUVER: ${dist.toStringAsFixed(0)}m');
          developer.log('DISTANCE TO MANEUVER: ${dist.toStringAsFixed(0)}m', name: 'Navigation');
        }

        // If close to waypoint (e.g. within 20 meters)
        if (dist <= 20.0) {
          if (!_announcedManeuvers.contains(_nextPointIndex)) {
            _announcedManeuvers.add(_nextPointIndex);
            _currentInstructionIndex = _nextPointIndex;
            _nextPointIndex += 1;

            if (_nextPointIndex >= _routePoints.length) {
              // Reached!
              _distanceRemaining = 0.0;
              _timeRemaining = 0.0;
              timer.cancel();
              _navigationTimer = null;

              final arrivedCommand = 'ARRIVED';
              final success = await SmartStickService.instance.sendNavigationCommand(arrivedCommand);
              print('DESTINATION REACHED');
              developer.log('DESTINATION REACHED', name: 'Navigation');
              if (success) {
                print('BLE COMMAND SENT: $arrivedCommand');
                developer.log('BLE COMMAND SENT: $arrivedCommand', name: 'Navigation');
              }

              _telemetry = _telemetry.copyWith(
                lastVoiceSpoken: 'You have arrived at ${location.name}.',
                lastUpdated: DateTime.now(),
              );
              _speak('You have arrived at ${location.name}.');
              notifyListeners();
            } else {
              // Send next command
              final nextInstr = _navigationInstructions[_currentInstructionIndex];
              final command = _commandFromInstruction(nextInstr);

              String maneuverLog = 'STRAIGHT';
              String speakMsg = 'Go straight.';
              if (command == 'TURN_LEFT') {
                maneuverLog = 'LEFT';
                speakMsg = 'Turn left.';
              } else if (command == 'TURN_RIGHT') {
                maneuverLog = 'RIGHT';
                speakMsg = 'Turn right.';
              }

              print('APPROACHING MANEUVER: $maneuverLog');
              developer.log('APPROACHING MANEUVER: $maneuverLog', name: 'Navigation');
              print('DISTANCE TO MANEUVER: ${dist.toStringAsFixed(0)}m');
              developer.log('DISTANCE TO MANEUVER: ${dist.toStringAsFixed(0)}m', name: 'Navigation');
              print('SENDING BLE COMMAND: $command');
              developer.log('SENDING BLE COMMAND: $command', name: 'Navigation');

              final success = await SmartStickService.instance.sendNavigationCommand(command);

              if (success) {
                print('BLE COMMAND SENT: $command');
                developer.log('BLE COMMAND SENT: $command', name: 'Navigation');
              }

              _telemetry = _telemetry.copyWith(
                lastVoiceSpoken: speakMsg,
                lastUpdated: DateTime.now(),
              );
              _speak(speakMsg);
              notifyListeners();
            }
          } else {
            // Already announced, just increment waypoint
            _currentInstructionIndex = _nextPointIndex;
            _nextPointIndex += 1;
            notifyListeners();
          }
        } else {
          // Fetch real GPS to see if user moved
          Position? currentPos;
          try {
            currentPos = await LocationService.getCurrentPosition();
          } catch (_) {
            currentPos = null;
          }

          if (currentPos != null) {
            // If user has moved > 15m from where navigation started, track them.
            // Otherwise, simulate walking towards target so stationary testing works!
            final double distanceMoved = LocationService.distanceBetween(
              currentPos.latitude, currentPos.longitude,
              initialPos.latitude, initialPos.longitude,
            );

            if (distanceMoved > 15.0) {
              // Update position to real GPS
              _currentLatitude = currentPos.latitude;
              _currentLongitude = currentPos.longitude;
            } else {
              // Simulator: step closer
              final stepRatio = 0.25; // 25% closer per tick
              _currentLatitude += (target.x - _currentLatitude) * stepRatio;
              _currentLongitude += (target.y - _currentLongitude) * stepRatio;
            }
          } else {
            // Simulator fallback: step closer
            final stepRatio = 0.25;
            _currentLatitude += (target.x - _currentLatitude) * stepRatio;
            _currentLongitude += (target.y - _currentLongitude) * stepRatio;
          }
        }

        // Compute remaining distance
        double totalDist = 0.0;
        if (_nextPointIndex < _routePoints.length) {
          totalDist += LocationService.distanceBetween(
            _currentLatitude, _currentLongitude,
            _routePoints[_nextPointIndex].x, _routePoints[_nextPointIndex].y,
          );
          for (int i = _nextPointIndex; i < _routePoints.length - 1; i++) {
            totalDist += LocationService.distanceBetween(
              _routePoints[i].x, _routePoints[i].y,
              _routePoints[i+1].x, _routePoints[i+1].y,
            );
          }
        }
        _distanceRemaining = totalDist;
        _timeRemaining = totalDist / 1.4; // 1.4 m/s walking speed
        notifyListeners();
      });
    } finally {
      _isRouteLoading = false;
      notifyListeners();
    }
  }

  // Distance from point to line segment formula helper
  double _distanceToSegment(double px, double py, double x1, double y1, double x2, double y2) {
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    if (dx == 0 && dy == 0) {
      return LocationService.distanceBetween(px, py, x1, y1);
    }
    final double t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy);
    if (t < 0) {
      return LocationService.distanceBetween(px, py, x1, y1);
    } else if (t > 1) {
      return LocationService.distanceBetween(px, py, x2, y2);
    }
    final double cx = x1 + t * dx;
    final double cy = y1 + t * dy;
    return LocationService.distanceBetween(px, py, cx, cy);
  }

  String _commandFromInstruction(String instruction) {
    final normalized = instruction.trim().toLowerCase();
    if (normalized.contains('left')) return 'TURN_LEFT';
    if (normalized.contains('right')) return 'TURN_RIGHT';
    if (normalized.contains('straight')) return 'STRAIGHT';
    if (normalized.contains('reached') || normalized.contains('arrived')) return 'ARRIVED';
    if (normalized.contains('cancel')) return 'NAVIGATION_CANCELLED';
    return 'STRAIGHT';
  }

  // Public control to stop navigation
  void stopNavigation() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _navigationInstructions = [];
    _currentInstructionIndex = -1;

    // Send NAVIGATION_CANCELLED command to the stick and print log
    final cancelCommand = 'NAVIGATION_CANCELLED';
    SmartStickService.instance.sendNavigationCommand(cancelCommand);
    print('BLE COMMAND SENT: $cancelCommand');
    developer.log('BLE COMMAND SENT: $cancelCommand', name: 'Navigation');

    notifyListeners();
  }

  String get navigationStatus {
    if (_currentInstructionIndex < 0) return 'Idle';
    return 'Navigating';
  }

  String get currentInstruction {
    if (_isRecalculating) {
      return "Route recalculating...";
    }
    if (_currentInstructionIndex < 0 ||
        _currentInstructionIndex >= _navigationInstructions.length) {
      return '';
    }
    return _navigationInstructions[_currentInstructionIndex];
  }

  String get nextInstruction {
    if (_isRecalculating) {
      return "";
    }
    final next = _currentInstructionIndex + 1;
    if (next < 0 || next >= _navigationInstructions.length) return '';
    return _navigationInstructions[next];
  }

  /// Builds a NavigationSession by reading current GPS and provider state.
  NavigationSession buildNavigationSession() {
    return NavigationSession(
      currentLatitude: _currentLatitude == 0.0 ? 12.9606322 : _currentLatitude,
      currentLongitude: _currentLongitude == 0.0 ? 77.5716324 : _currentLongitude,
      destinationName: _activeDestination?.name ?? '',
      destinationLatitude: _activeDestination?.latitude ?? 0.0,
      destinationLongitude: _activeDestination?.longitude ?? 0.0,
      navigationStatus: navigationStatus,
      currentInstruction: currentInstruction,
      nextInstruction: nextInstruction,
    );
  }

  void _speak(String text) {
    // Disabled: Flutter app must NOT speak navigation instructions.
    // The only device that should produce navigation voice audio is the ESP32 stick.
  }

  List<String> _buildMockRouteInstructions(NavigationLocation location) {
    return [
      'Continue straight',
      'Turn left',
      'Continue straight',
      'Turn right',
      'Continue straight',
      'You have reached your destination',
    ];
  }

  Future<void> testRailwayStationNavigation() async {
    final railway = _savedLocations.firstWhere(
      (item) => item.name.toLowerCase() == 'railway station',
      orElse: () => _defaultLocations.first,
    );
    await _startNavigationToLocation(railway);
  }

  /// Test a simple navigation sequence matching the requested test flow:
  /// DESTINATION_SELECTED -> STRAIGHT -> TURN_LEFT -> STRAIGHT -> ARRIVED
  Future<void> testSimpleNavigation() async {
    final railway = _savedLocations.firstWhere(
      (item) => item.name.toLowerCase() == 'railway station',
      orElse: () => _defaultLocations.first,
    );

    _activeDestination = railway;
    _navigationInstructions = [
      'Continue straight',
      'Turn left',
      'Continue straight',
      'You have reached your destination',
    ];
    _currentInstructionIndex = 0;
    notifyListeners();

    addAlert(
      'Destination Selected',
      '${railway.name} selected for test navigation',
      'LOW',
      Icons.navigation,
    );

    await SmartStickService.instance.sendNavigationCommand(
      'DESTINATION_SELECTED:${railway.name}',
    );

    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) async {
      if (_currentInstructionIndex < 0 ||
          _currentInstructionIndex >= _navigationInstructions.length) {
        timer.cancel();
        _currentInstructionIndex = -1;
        notifyListeners();
        return;
      }
      final instr = _navigationInstructions[_currentInstructionIndex];
      await SmartStickService.instance.sendNavigationCommand(
        instr.toUpperCase().replaceAll(' ', '_'),
      );
      _currentInstructionIndex += 1;
      if (_currentInstructionIndex >= _navigationInstructions.length) {
        await SmartStickService.instance.sendNavigationCommand('ARRIVED');
        timer.cancel();
        _currentInstructionIndex = -1;
      }
      notifyListeners();
    });
  }

  // Connect / Disconnect ESP32
  void toggleBluetoothConnection() {
    final currentlyConnected = _hardwareInfo.isEsp32Connected;
    _hardwareInfo = DeviceHardwareInfo(
      isEsp32Connected: !currentlyConnected,
      firmwareVersion: _hardwareInfo.firmwareVersion,
      bluetoothAddress: _hardwareInfo.bluetoothAddress,
      signalStrengthDb: !currentlyConnected ? -55 : -100,
      batteryHealth: _hardwareInfo.batteryHealth,
      storageUsedPercent: _hardwareInfo.storageUsedPercent,
      microSdStatus: !currentlyConnected ? "Mounted (16GB)" : "Offline",
      dfPlayerStatus: !currentlyConnected ? "Ready" : "Offline",
      speakerStatus: !currentlyConnected ? "Connected" : "Disconnected",
    );

    _telemetry = _telemetry.copyWith(
      bluetoothStrength: !currentlyConnected ? 0.90 : 0.0,
      lastUpdated: DateTime.now(),
    );

    if (!currentlyConnected) {
      addAlert(
        "Device Connected",
        "ESP32 established Bluetooth link",
        "LOW",
        Icons.bluetooth_connected,
      );
    } else {
      addAlert(
        "Device Disconnected",
        "Bluetooth link with ESP32 lost",
        "HIGH",
        Icons.bluetooth_disabled,
      );
    }

    notifyListeners();
  }

  // Trigger SOS
  void triggerSos() {
    _isSosActive = true;
    _telemetry = _telemetry.copyWith(
      threatLevel: "CRITICAL",
      lastVoiceSpoken: "SOS Activated. Seeking Guardian Assistance.",
      lastUpdated: DateTime.now(),
    );
    addAlert(
      "SOS Activated",
      "Emergency signal triggered by blind user",
      "CRITICAL",
      Icons.emergency,
    );
    notifyListeners();
  }

  // Dismiss SOS
  void dismissSos() {
    _isSosActive = false;
    _telemetry = _telemetry.copyWith(
      threatLevel: "LOW",
      lastVoiceSpoken: "Safety mode restored.",
      lastUpdated: DateTime.now(),
    );
    addAlert(
      "SOS Resolved",
      "Emergency event cleared by caretaker",
      "LOW",
      Icons.gpp_good,
    );
    notifyListeners();
  }

  // Switch Mode
  void toggleMode() {
    final nextMode = _telemetry.currentMode == "OUTDOOR" ? "INDOOR" : "OUTDOOR";
    _telemetry = _telemetry.copyWith(
      currentMode: nextMode,
      lastVoiceSpoken: "Switched to $nextMode Mode.",
      lastUpdated: DateTime.now(),
    );
    addAlert(
      "Mode Switched",
      "Device profile updated to $nextMode",
      "LOW",
      Icons.sync,
    );
    notifyListeners();
  }

  // Add Alert to History
  void addAlert(
    String title,
    String description,
    String priority,
    IconData icon,
  ) {
    _alerts.insert(
      0,
      AlertHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        title: title,
        description: description,
        priority: priority,
        icon: icon,
      ),
    );
    if (_alerts.length > 50) {
      _alerts.removeLast();
    }
    notifyListeners();
  }

  // Clear Alert History
  void clearHistory() {
    _alerts.clear();
    notifyListeners();
  }

  // Start realistic telemetry simulation
  void startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (BleService.instance.isConnected) return; // Skip simulation if real device is connected
      if (!_hardwareInfo.isEsp32Connected) return;

      // Don't update if SOS is active, override telemetry
      if (_isSosActive) return;

      // Random telemetry variations
      final int newFront = max(
        20,
        min(300, _telemetry.frontDistanceCm + _random.nextInt(41) - 20),
      );
      final int newPit = max(
        80,
        min(200, _telemetry.pitDistanceCm + _random.nextInt(21) - 10),
      );
      final bool newWater =
          _random.nextDouble() < 0.08; // 8% chance water is detected

      // Battery slowly drops or stays
      int newBattery = _telemetry.batteryPercent;
      if (_random.nextDouble() < 0.05) {
        newBattery = max(5, _telemetry.batteryPercent - 1);
      }

      // Generate random objects & alerts
      List<DetectedObject> objects = List.from(_telemetry.detectedObjects);
      String threat = "LOW";
      String voice = _telemetry.lastVoiceSpoken;
      IconData alertIcon = Icons.info_outline;

      final bool isWithinSelectionGracePeriod = _lastDestinationSelectionTime != null &&
          DateTime.now().difference(_lastDestinationSelectionTime!).inSeconds < 5;

      if (newFront < 50) {
        threat = "HIGH";
        if (!isWithinSelectionGracePeriod) {
          voice = "Obstacle Ahead. Stop.";
        }
        alertIcon = Icons.warning_amber_rounded;
        objects = [
          DetectedObject(
            label: _random.nextBool() ? "Vehicle" : "Person",
            direction: "Ahead",
          ),
          ..._telemetry.detectedObjects.take(1),
        ];
        if (_random.nextDouble() < 0.3) {
          addAlert(
            "Obstacle Ahead",
            "Front collision pathway blocked at ${newFront}cm",
            "HIGH",
            alertIcon,
          );
        }
      } else if (newPit < 100) {
        threat = "MEDIUM";
        if (!isWithinSelectionGracePeriod) {
          voice = "Pit Ahead. Watch step.";
        }
        alertIcon = Icons.analytics_outlined;
        if (_random.nextDouble() < 0.3) {
          addAlert(
            "Drop-off Detected",
            "Pit/Stairs detected at ${newPit}cm",
            "MEDIUM",
            alertIcon,
          );
        }
      } else if (newWater) {
        threat = "MEDIUM";
        if (!isWithinSelectionGracePeriod) {
          voice = "Water Detected. Change path.";
        }
        alertIcon = Icons.water_drop;
        addAlert(
          "Water Detected",
          "Liquid surface detected on pathway",
          "MEDIUM",
          alertIcon,
        );
      } else {
        threat = "LOW";
        if (navigationStatus == 'Navigating') {
          voice = currentInstruction;
        } else {
          if (_random.nextDouble() < 0.15) {
            voice = "Path Clear.";
          }
        }
      }

      // Random signal strength fluctuation
      final newRssi = max(
        -95,
        min(-45, _hardwareInfo.signalStrengthDb + _random.nextInt(7) - 3),
      );
      _hardwareInfo = DeviceHardwareInfo(
        isEsp32Connected: true,
        firmwareVersion: _hardwareInfo.firmwareVersion,
        bluetoothAddress: _hardwareInfo.bluetoothAddress,
        signalStrengthDb: newRssi,
        batteryHealth: _hardwareInfo.batteryHealth,
        storageUsedPercent: _hardwareInfo.storageUsedPercent,
        microSdStatus: _hardwareInfo.microSdStatus,
        dfPlayerStatus: _hardwareInfo.dfPlayerStatus,
        speakerStatus: _hardwareInfo.speakerStatus,
      );

      final oldVoice = _telemetry.lastVoiceSpoken;

      _telemetry = NavigationTelemetry(
        frontDistanceCm: newFront,
        pitDistanceCm: newPit,
        waterDetected: newWater,
        batteryPercent: newBattery,
        isCharging: _telemetry.isCharging,
        currentMode: _telemetry.currentMode,
        sceneScore: max(
          1,
          min(5, _telemetry.sceneScore + (_random.nextBool() ? 1 : -1)),
        ),
        threatLevel: threat,
        lastVoiceSpoken: voice,
        detectedObjects: objects,
        bluetoothStrength: (100 + newRssi) / 70.0, // Scale to 0.0 - 1.0 approx
        lastUpdated: DateTime.now(),
      );

      if (oldVoice != voice) {
        _speak(voice);
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
