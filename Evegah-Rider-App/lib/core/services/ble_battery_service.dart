import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleBatteryState {
  disconnected,
  scanning,
  connecting,
  connected,
}

class BleBatteryService {
  // --- SINGLETON SETUP ---
  static final BleBatteryService instance = BleBatteryService._internal();
  factory BleBatteryService() => instance;
  BleBatteryService._internal();

  // --- NOTIFIERS FOR UI ---
  final ValueNotifier<BleBatteryState> connectionState = ValueNotifier<BleBatteryState>(BleBatteryState.disconnected);
  final ValueNotifier<double> batteryPercentage = ValueNotifier<double>(78.0); // Default to 78% mock
  final ValueNotifier<String?> connectedDeviceName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<List<ScanResult>> scannedDevices = ValueNotifier<List<ScanResult>>([]);

  // --- PRIVATE BLE VARIABLES ---
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic; // ff01
  BluetoothCharacteristic? _dataCharacteristic;  // fff2 or fallback
  BluetoothCharacteristic? _passCharacteristic;  // ff05
  StreamSubscription<BluetoothConnectionState>? _connStateSub;
  StreamSubscription<List<ScanResult>>? _scanResultSub;
  Timer? _queryTimer;
  final List<int> _accumulator = [];
  StreamSubscription<List<int>>? _notifySub;
  bool _isSimulated = false;

  // --- CONFIG / HANDSHAKE BYTES ---
  static const List<int> _hiLinkPassword = [0x48, 0x69, 0x4C, 0x69, 0x6E, 0x6B]; // "HiLink"
  static const List<int> _modbusInitProbe = [0xD2, 0x03, 0x00, 0x00, 0x00, 0x7E, 0x90, 0xAA];
  static const List<int> _modbusReadLive = [0xD2, 0x03, 0x00, 0x00, 0x00, 0x3E, 0xD7, 0xB9];

  // --- PUBLIC API ---

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses[Permission.location] == PermissionStatus.granted &&
           statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
           statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
  }

  Future<void> startScan() async {
    errorMessage.value = null;
    scannedDevices.value = [];
    final hasPerms = await checkPermissions();
    if (!hasPerms) {
      errorMessage.value = "Permissions denied. Please grant Bluetooth and Location permissions.";
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        errorMessage.value = "Please turn on Bluetooth.";
        return;
      }
    }

    await disconnect();

    connectionState.value = BleBatteryState.scanning;
    _scanResultSub?.cancel();
    
    _scanResultSub = FlutterBluePlus.scanResults.listen((results) {
      final List<ScanResult> matches = [];
      for (var r in results) {
        final pName = r.device.platformName.toUpperCase();
        final aName = r.advertisementData.advName.toUpperCase();
        if (pName.contains("DL-") || aName.contains("DL-")) {
          matches.add(r);
        }
      }
      scannedDevices.value = matches;
    }, onError: (e) {
      errorMessage.value = "Scan error: $e";
      connectionState.value = BleBatteryState.disconnected;
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [],
      );
    } catch (e) {
      errorMessage.value = "Failed to start scan: $e";
      connectionState.value = BleBatteryState.disconnected;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanResultSub?.cancel();
    if (connectionState.value == BleBatteryState.scanning) {
      connectionState.value = BleBatteryState.disconnected;
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _isSimulated = false;
    connectionState.value = BleBatteryState.connecting;
    _connectedDevice = device;
    connectedDeviceName.value = device.platformName.isNotEmpty ? device.platformName : "DL Battery";

    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      connectionState.value = BleBatteryState.connected;

      _connStateSub?.cancel();
      _connStateSub = device.connectionState.listen((cs) {
        if (cs == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      final services = await device.discoverServices();
      await _setupHandshake(device, services);

    } catch (e) {
      errorMessage.value = "Connection failed: $e";
      _handleDisconnect();
    }
  }

  Future<void> disconnect() async {
    _queryTimer?.cancel();
    _connStateSub?.cancel();
    _notifySub?.cancel();
    _accumulator.clear();
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
    
    _isSimulated = false;
    connectedDeviceName.value = null;
    connectionState.value = BleBatteryState.disconnected;
  }

  // --- SIMULATION API ---

  bool get isSimulated => _isSimulated;

  void startSimulation(double startSoc) {
    disconnect();
    _isSimulated = true;
    connectionState.value = BleBatteryState.connected;
    connectedDeviceName.value = "Simulated DL Battery";
    batteryPercentage.value = startSoc;
  }

  void updateSimulatedSoc(double newSoc) {
    if (_isSimulated) {
      batteryPercentage.value = newSoc;
    }
  }

  // --- PRIVATE METHODS ---

  void _handleDisconnect() {
    _queryTimer?.cancel();
    _connStateSub?.cancel();
    _notifySub?.cancel();
    _accumulator.clear();
    _connectedDevice = null;
    connectedDeviceName.value = null;
    connectionState.value = BleBatteryState.disconnected;
  }

  Future<void> _setupHandshake(BluetoothDevice device, List<BluetoothService> services) async {
    final allChars = services.expand((s) => s.characteristics).toList();

    BluetoothCharacteristic? ff01; // auth write
    BluetoothCharacteristic? ff02; // notify
    BluetoothCharacteristic? ff05; // password write
    BluetoothCharacteristic? fff1; // data notify
    BluetoothCharacteristic? fff2; // data write

    for (var ch in allChars) {
      final uuid = ch.uuid.toString().toLowerCase();
      if (uuid.endsWith('ff01')) ff01 = ch;
      if (uuid.endsWith('ff02')) ff02 = ch;
      if (uuid.endsWith('ff05')) ff05 = ch;
      if (uuid.endsWith('fff1')) fff1 = ch;
      if (uuid.endsWith('fff2')) fff2 = ch;
    }

    _writeCharacteristic = ff01 ?? allChars.firstWhere((c) => c.properties.write || c.properties.writeWithoutResponse, orElse: () => allChars.first);
    _dataCharacteristic = fff2 ?? _writeCharacteristic;
    _passCharacteristic = ff05 ?? _writeCharacteristic;

    BluetoothCharacteristic? notifyChar = ff02 ?? fff1 ?? allChars.firstWhere((c) => c.properties.notify, orElse: () => allChars.first);

    await notifyChar.setNotifyValue(true);
    _notifySub?.cancel();
    _notifySub = notifyChar.onValueReceived.listen((value) {
      _onRxData(value);
    });

    if (_writeCharacteristic != null) {
      final woResp = !_writeCharacteristic!.properties.write && _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(_modbusInitProbe, withoutResponse: woResp);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (_passCharacteristic != null) {
      final woResp = !_passCharacteristic!.properties.write && _passCharacteristic!.properties.writeWithoutResponse;
      await _passCharacteristic!.write(_hiLinkPassword, withoutResponse: woResp);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    _queryTimer?.cancel();
    _queryTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_dataCharacteristic != null) {
        try {
          final woResp = !_dataCharacteristic!.properties.write && _dataCharacteristic!.properties.writeWithoutResponse;
          await _dataCharacteristic!.write(_modbusReadLive, withoutResponse: woResp);
        } catch (_) {}
      }
    });
  }

  void _onRxData(List<int> data) {
    if (data.isEmpty) return;
    _accumulator.addAll(data);

    while (_accumulator.length >= 5) {
      int startIdx = -1;
      for (int i = 0; i < _accumulator.length - 1; i++) {
        if (_accumulator[i] == 0xD2 && _accumulator[i + 1] == 0x03) {
          startIdx = i;
          break;
        }
      }

      if (startIdx == -1) {
        if (_accumulator.length > 3) {
          _accumulator.removeRange(0, _accumulator.length - 3);
        }
        break;
      }

      if (startIdx > 0) {
        _accumulator.removeRange(0, startIdx);
        continue;
      }

      final byteCount = _accumulator[2];
      final frameLen = 3 + byteCount + 2;

      if (_accumulator.length < frameLen) {
        break;
      }

      final frame = _accumulator.sublist(0, frameLen);
      if (_validateCrc(frame)) {
        _parseFrame(frame.sublist(3, 3 + byteCount));
        _accumulator.removeRange(0, frameLen);
      } else {
        _accumulator.removeAt(0);
      }
    }
  }

  bool _validateCrc(List<int> frame) {
    if (frame.length < 3) return false;
    final crc = _crc16(frame.sublist(0, frame.length - 2));
    final rxLo = frame[frame.length - 2];
    final rxHi = frame[frame.length - 1];
    return crc == ((rxHi << 8) | rxLo);
  }

  int _crc16(List<int> data) {
    int crc = 0xFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc;
  }

  void _parseFrame(List<int> payload) {
    if (payload.length < 92) return;
    final rawSoc = (payload[84] << 8) | payload[85];
    if (rawSoc > 0 && rawSoc <= 1000) {
      final double val = rawSoc / 10.0;
      batteryPercentage.value = double.parse(val.toStringAsFixed(1));
    }
  }
}
