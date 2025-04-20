import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_state.dart';
import 'ble_constants.dart';

class BleService extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _statusSubscription;
  StreamSubscription<List<int>>? _lastWateredSubscription;

  static const String _storedDeviceIdKey = 'last_connected_device_id';

  QualifiedCharacteristic? _modeChar;
  QualifiedCharacteristic? _intervalChar;
  QualifiedCharacteristic? _amountChar;
  QualifiedCharacteristic? _waterNowChar;
  QualifiedCharacteristic? _statusChar;
  QualifiedCharacteristic? _lastWateredChar;

  PlantState _state = PlantState(
    mode: PlantMode.off,
    intervalMinutes: 60,
    amountMl: 100,
    isWatering: false,
    lastWateredSeconds: 0,
  );

  PlantState get state => _state;
  bool get isConnected => _connectionSubscription != null;
  bool _isScanning = false;
  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isConnected = false;
  bool _isWatering = false;
  int _lastWateredSeconds = 0;
  String? _connectedDeviceId;

  BleService() {
    _checkExistingConnection();
  }

  Future<void> _checkExistingConnection() async {
    print('Checking for existing connection...');
    await _startDeviceDiscovery(autoConnect: true);
  }

  Future<void> _startDeviceDiscovery({bool autoConnect = false}) async {
    if (_isScanning) return;

    print('Starting BLE scan...');
    if (!await _requestPermissions()) {
      print('Required permissions not granted');
      return;
    }

    if (_isConnected && _connectedDeviceId != null) {
      print('Already connected to device: $_connectedDeviceId');
      return;
    }

    _isScanning = true;
    _discoveredDevices = [];
    notifyListeners();

    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [Uuid.parse(wateringServiceUuid)],
      scanMode: ScanMode.lowLatency,
    ).listen((device) async {
      print('Found device: ${device.name} (${device.id})');
      if (device.name.startsWith(DEVICE_NAME_PREFIX)) {
        if (autoConnect) {
          print('Auto-connecting to device...');
          await connectToDevice(device);
          await stopScan();
        } else {
          _addDiscoveredDevice(device);
        }
      }
    }, onError: (error) {
      print('Scan error: $error');
      _isScanning = false;
      notifyListeners();
    });

    // Cancel scan after 5 seconds if no device found
    if (autoConnect) {
      Future.delayed(const Duration(seconds: 5), () async {
        await stopScan();
      });
    }
  }

  void _addDiscoveredDevice(DiscoveredDevice device) {
    if (!_discoveredDevices.any((d) => d.id == device.id)) {
      print('Adding new device to list');
      _discoveredDevices.add(device);
      notifyListeners();
    }
  }

  Future<void> startScan() async {
    await _startDeviceDiscovery(autoConnect: false);
  }

  Future<void> stopScan() async {
    print('Stopping BLE scan...');
    await _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    print('Connecting to device: ${device.name} (${device.id})');

    // First disconnect from any existing connection
    await disconnect();

    _connectionSubscription?.cancel();
    _connectedDeviceId = device.id;

    _connectionSubscription = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((update) async {
      print('Connection state update: ${update.connectionState}');
      if (update.connectionState == DeviceConnectionState.connected) {
        _isConnected = true;
        await _discoverServices(device.id);
        notifyListeners();
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        _isConnected = false;
        _connectedDeviceId = null;
        _cleanupSubscriptions();
        notifyListeners();
      }
    });
  }

  Future<void> _discoverServices(String deviceId) async {
    print('Discovering services...');
    try {
      final services = await _ble.discoverServices(deviceId);
      for (final service in services) {
        print('Found service: ${service.serviceId}');
        if (service.serviceId == Uuid.parse(wateringServiceUuid)) {
          print('Found watering service!');
          for (final characteristic in service.characteristics) {
            _setupCharacteristic(characteristic, deviceId);
          }
          // Read initial state after discovering all characteristics
          await readInitialState();
        }
      }
    } catch (e) {
      print('Error discovering services: $e');
    }
  }

  Future<void> readInitialState() async {
    if (!isConnected) return;

    try {
      // Read mode
      final modeData = await _readCharacteristic(_modeChar);
      if (modeData.isNotEmpty) {
        _state = _state.copyWith(mode: PlantMode.values[modeData[0]]);
      }

      // Read interval
      final intervalData = await _readCharacteristic(_intervalChar);
      if (intervalData.length >= 2) {
        final interval = intervalData[0] | (intervalData[1] << 8);
        _state = _state.copyWith(intervalMinutes: interval);
      }

      // Read amount
      final amountData = await _readCharacteristic(_amountChar);
      if (amountData.length >= 2) {
        final amount = amountData[0] | (amountData[1] << 8);
        _state = _state.copyWith(amountMl: amount);
      }

      // Read status
      final statusData = await _readCharacteristic(_statusChar);
      if (statusData.isNotEmpty) {
        _isWatering = statusData[0] == 1;
        _state = _state.copyWith(isWatering: _isWatering);
      }

      // Read last watered
      final lastWateredData = await _readCharacteristic(_lastWateredChar);
      if (lastWateredData.length >= 4) {
        _lastWateredSeconds = lastWateredData[0] |
            (lastWateredData[1] << 8) |
            (lastWateredData[2] << 16) |
            (lastWateredData[3] << 24);
        _state = _state.copyWith(lastWateredSeconds: _lastWateredSeconds);
      }

      notifyListeners();
    } catch (e) {
      print('Error reading initial state: $e');
    }
  }

  Future<List<int>> _readCharacteristic(
      QualifiedCharacteristic? characteristic) async {
    if (characteristic == null) return [];
    return await _ble.readCharacteristic(characteristic);
  }

  void _setupCharacteristic(
      DiscoveredCharacteristic characteristic, String deviceId) {
    final qualifiedChar = QualifiedCharacteristic(
      serviceId: characteristic.serviceId,
      characteristicId: characteristic.characteristicId,
      deviceId: deviceId,
    );

    if (characteristic.characteristicId == Uuid.parse(modeCharUuid)) {
      print('Found mode characteristic');
      _modeChar = qualifiedChar;
    } else if (characteristic.characteristicId ==
        Uuid.parse(intervalCharUuid)) {
      print('Found interval characteristic');
      _intervalChar = qualifiedChar;
    } else if (characteristic.characteristicId == Uuid.parse(amountCharUuid)) {
      print('Found amount characteristic');
      _amountChar = qualifiedChar;
    } else if (characteristic.characteristicId ==
        Uuid.parse(waterNowCharUuid)) {
      print('Found water now characteristic');
      _waterNowChar = qualifiedChar;
    } else if (characteristic.characteristicId == Uuid.parse(statusCharUuid)) {
      print('Found status characteristic');
      _statusChar = qualifiedChar;
      _subscribeToStatus();
    } else if (characteristic.characteristicId ==
        Uuid.parse(lastWateredCharUuid)) {
      print('Found last watered characteristic');
      _lastWateredChar = qualifiedChar;
      _subscribeToLastWatered();
    }
  }

  void _subscribeToStatus() {
    _statusSubscription?.cancel();
    if (_statusChar != null) {
      print('Subscribing to status notifications');
      _statusSubscription =
          _ble.subscribeToCharacteristic(_statusChar!).listen((data) {
        if (data.isNotEmpty) {
          final isWatering = data[0] == 1;
          print(
              'Status update received: ${isWatering ? "Watering" : "Idle"} (raw: $data)');
          _isWatering = isWatering;
          _state = _state.copyWith(isWatering: isWatering);
          notifyListeners();
        } else {
          print('Warning: Empty status update received');
        }
      }, onError: (error) {
        print('Error in status subscription: $error');
      });
    }
  }

  void _subscribeToLastWatered() {
    _lastWateredSubscription?.cancel();
    if (_lastWateredChar != null) {
      print('Subscribing to last watered notifications');
      _lastWateredSubscription =
          _ble.subscribeToCharacteristic(_lastWateredChar!).listen((data) {
        if (data.length >= 4) {
          // Convert from little-endian to big-endian
          final lastWatered =
              data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
          print(
              'Last watered update received: $lastWatered seconds (raw: $data)');
          _lastWateredSeconds = lastWatered;
          _state = _state.copyWith(lastWateredSeconds: lastWatered);
          notifyListeners();
        } else {
          print(
              'Warning: Invalid last watered data received (length: ${data.length})');
        }
      }, onError: (error) {
        print('Error in last watered subscription: $error');
      });
    }
  }

  // Helper method to update state and notify listeners
  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }

  void _cleanupSubscriptions() {
    print('Cleaning up subscriptions');
    _statusSubscription?.cancel();
    _lastWateredSubscription?.cancel();
    _statusSubscription = null;
    _lastWateredSubscription = null;
    _modeChar = null;
    _intervalChar = null;
    _amountChar = null;
    _waterNowChar = null;
    _statusChar = null;
    _lastWateredChar = null;
  }

  Future<void> setMode(PlantMode mode) async {
    if (_modeChar != null) {
      await _ble.writeCharacteristicWithResponse(
        _modeChar!,
        value: [mode.index],
      );
      setState(() {
        _state = _state.copyWith(mode: mode);
      });
    }
  }

  Future<void> setInterval(int minutes) async {
    if (_intervalChar != null) {
      // Convert to little-endian
      final value = [minutes & 0xFF, minutes >> 8];
      await _ble.writeCharacteristicWithResponse(
        _intervalChar!,
        value: value,
      );
      setState(() {
        _state = _state.copyWith(intervalMinutes: minutes);
      });
    }
  }

  Future<void> setAmount(int ml) async {
    if (_amountChar != null) {
      // Convert to little-endian
      final value = [ml & 0xFF, ml >> 8];
      await _ble.writeCharacteristicWithResponse(
        _amountChar!,
        value: value,
      );
      setState(() {
        _state = _state.copyWith(amountMl: ml);
      });
    }
  }

  Future<void> triggerWatering() async {
    if (_waterNowChar != null) {
      await _ble.writeCharacteristicWithResponse(
        _waterNowChar!,
        value: [1],
      );
      setState(() {
        _isWatering = true;
        _state = _state.copyWith(isWatering: true);
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _cleanupSubscriptions();
    super.dispose();
  }

  // Getters for UI
  bool get isScanning => _isScanning;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  bool get isWatering => _state.isWatering;
  int get lastWateredSeconds => _state.lastWateredSeconds;

  String? get connectedDeviceId => _connectedDeviceId;

  Future<void> disconnect() async {
    print('Disconnecting from device...');
    try {
      // Cancel all subscriptions first
      _connectionSubscription?.cancel();
      _scanSubscription?.cancel();
      _statusSubscription?.cancel();
      _lastWateredSubscription?.cancel();

      // Clear all state
      _isConnected = false;
      _isScanning = false;
      _isWatering = false;
      _connectedDeviceId = null;
      _discoveredDevices = [];

      // Clear characteristic references
      _modeChar = null;
      _intervalChar = null;
      _amountChar = null;
      _waterNowChar = null;
      _statusChar = null;
      _lastWateredChar = null;

      // Reset state
      _state = PlantState(
        mode: PlantMode.off,
        intervalMinutes: 60,
        amountMl: 100,
        isWatering: false,
        lastWateredSeconds: 0,
      );

      notifyListeners();
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    print('Requesting permissions...');

    // Request location permission
    var locationStatus = await Permission.location.request();
    print('Location permission status: $locationStatus');

    // Request Bluetooth permissions
    var bluetoothScan = await Permission.bluetoothScan.request();
    print('Bluetooth scan permission status: $bluetoothScan');
    var bluetoothConnect = await Permission.bluetoothConnect.request();
    print('Bluetooth connect permission status: $bluetoothConnect');

    return locationStatus.isGranted &&
        bluetoothScan.isGranted &&
        bluetoothConnect.isGranted;
  }
}
