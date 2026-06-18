import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dio/dio.dart';
import 'package:evegah_maintenance/core/constants/api_constants.dart';
import 'package:evegah_maintenance/core/services/location_service.dart';
import '../../data/models/battery_model.dart';

// ---------------------------------------------------------------------------
// BatteryState
// ---------------------------------------------------------------------------
class BatteryState {
  final bool isScanning;
  final List<ScanResult> scannedDevices;
  final List<BatteryModel> connectedBatteries;
  final String errorMessage;
  final BluetoothAdapterState adapterState;
  final List<String> recentActivity;
  /// Per-device raw BLE hex log: deviceId -> list of "[UUID] HEX" strings
  final Map<String, List<String>> rawDataLog;

  BatteryState({
    this.isScanning = false,
    this.scannedDevices = const [],
    this.connectedBatteries = const [],
    this.errorMessage = '',
    this.adapterState = BluetoothAdapterState.unknown,
    this.recentActivity = const [],
    this.rawDataLog = const {},
  });

  BatteryState copyWith({
    bool? isScanning,
    List<ScanResult>? scannedDevices,
    List<BatteryModel>? connectedBatteries,
    String? errorMessage,
    BluetoothAdapterState? adapterState,
    List<String>? recentActivity,
    Map<String, List<String>>? rawDataLog,
  }) {
    return BatteryState(
      isScanning: isScanning ?? this.isScanning,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      connectedBatteries: connectedBatteries ?? this.connectedBatteries,
      errorMessage: errorMessage ?? this.errorMessage,
      adapterState: adapterState ?? this.adapterState,
      recentActivity: recentActivity ?? this.recentActivity,
      rawDataLog: rawDataLog ?? this.rawDataLog,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final batteryProvider =
    StateNotifierProvider<BatteryNotifier, BatteryState>((ref) {
  return BatteryNotifier();
});

// ---------------------------------------------------------------------------
// BatteryNotifier
// ---------------------------------------------------------------------------
class BatteryNotifier extends StateNotifier<BatteryState> {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  /// Per-device periodic query timer
  final Map<String, Timer> _queryTimers = {};

  /// Per-device write characteristic for auth/probe commands (ff01)
  final Map<String, BluetoothCharacteristic> _writeCharacteristics = {};

  /// Per-device write characteristic for Modbus data commands (FFF2)
  final Map<String, BluetoothCharacteristic> _dataCharacteristics = {};

  /// Per-device RX byte accumulator (for multi-packet Modbus responses)
  final Map<String, List<int>> _accumulators = {};

  /// Per-device active notify stream subscriptions
  final Map<String, List<StreamSubscription<List<int>>>> _notifySubs = {};

  final Random _random = Random();

  final FlutterTts _tts = FlutterTts();
  final Set<String> _voicedFullyCharged = {};

  // ── BMS Command Constants (confirmed from nRF Connect + user hex captures) ──

  // Data channel commands — sent to FFF2, responses come on FFF1
  // Read 62 registers from 0x0080 (matches user's known hex dump D2 03 7C...)
  static const List<int> _modbusRead62 = [
    0xD2, 0x03, 0x00, 0x80, 0x00, 0x3E, 0xD6, 0x51,
  ];

  // Read 62 registers from 0x0000 (confirmed from nRF Connect FFF2 screenshot)
  static const List<int> _modbusRead62From0 = [
    0xD2, 0x03, 0x00, 0x00, 0x00, 0x3E, 0xD7, 0xB9,
  ];

  // Auth channel probe — sent to ff01 to wake BMS
  // Confirmed: D2 03 00 00 00 7E 90 AA
  static const List<int> _modbusInitProbe = [
    0xD2, 0x03, 0x00, 0x00, 0x00, 0x7E, 0x90, 0xAA,
  ];

  // Track whether each device has been authenticated
  final Map<String, bool> _authenticated = {};

  BatteryNotifier() : super(BatteryState()) {
    _init();
  }

  void _init() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((s) {
      state = state.copyWith(adapterState: s);
    });
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Permissions & Scan
  // ---------------------------------------------------------------------------
  Future<bool> checkAndRequestPermissions() async {
    bool ok = true;
    if (await Permission.location.request().isDenied) ok = false;
    if (await Permission.bluetoothScan.request().isDenied) ok = false;
    if (await Permission.bluetoothConnect.request().isDenied) ok = false;
    return ok;
  }

  Future<void> startScan() async {
    final permissionsOk = await checkAndRequestPermissions();
    if (!permissionsOk) {
      state = state.copyWith(
          errorMessage: 'Bluetooth or Location permissions denied.');
      return;
    }

    if (state.adapterState != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        state = state.copyWith(errorMessage: 'Please turn on Bluetooth.');
        return;
      }
    }

    state = state.copyWith(
        isScanning: true, scannedDevices: [], errorMessage: '');

    _scanResultsSubscription?.cancel();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      final Map<String, ScanResult> unique = {};
      for (var r in results) {
        final pName = r.device.platformName.toUpperCase();
        final aName = r.advertisementData.advName.toUpperCase();
        if (pName.contains('DL-') || aName.contains('DL-')) {
          unique[r.device.remoteId.str] = r;
        }
      }
      state = state.copyWith(scannedDevices: unique.values.toList());
    }, onError: (e) {
      state = state.copyWith(errorMessage: 'Scanning error: $e');
    });

    _isScanningSubscription?.cancel();
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      state = state.copyWith(isScanning: scanning);
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [],
      );
    } catch (e) {
      state = state.copyWith(
          isScanning: false, errorMessage: 'Failed to start scan: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    state = state.copyWith(isScanning: false);
  }

  // ---------------------------------------------------------------------------
  // Connect
  // ---------------------------------------------------------------------------
  Future<void> connectToDevice(BluetoothDevice device) async {
    final alreadyIn =
        state.connectedBatteries.any((b) => b.id == device.remoteId.str);
    if (alreadyIn) {
      final existing = state.connectedBatteries
          .firstWhere((b) => b.id == device.remoteId.str);
      if (existing.status == BatteryStatus.connected) return;
    }

    final newBattery = BatteryModel(
      id: device.remoteId.str,
      name: device.platformName.isNotEmpty
          ? device.platformName
          : 'DL Battery (${device.remoteId.str.substring(0, 5)})',
      soc: 0.0,
      temperature: 0.0,
      voltage: 0.0,
      current: 0.0,
      rssi: -70,
      status: BatteryStatus.connecting,
      device: device,
    );

    state = state.copyWith(
        connectedBatteries: [...state.connectedBatteries, newBattery]);

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      state = state.copyWith(
        connectedBatteries: state.connectedBatteries.map((b) {
          if (b.id == device.remoteId.str) {
            return b.copyWith(status: BatteryStatus.connected);
          }
          return b;
        }).toList(),
      );

      _addActivityLog('${newBattery.name} connected');

      device.connectionState.listen((cs) {
        if (cs == BluetoothConnectionState.disconnected) {
          _handleDisconnect(device.remoteId.str);
        }
      });

      final services = await device.discoverServices();
      await _setupBmsSubscriptions(device, services);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to connect to ${newBattery.name}: $e',
        connectedBatteries: state.connectedBatteries
            .where((b) => b.id != device.remoteId.str)
            .toList(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Setup BMS subscriptions (HiLink / Modbus RTU protocol)
  //
  // BLE Communication Map (confirmed from device logs):
  //   Write data → 02f00000-0000-0000-0000-00000000ff01
  //   Password   → 02f00000-0000-0000-0000-00000000ff05  ← KEY!
  //   Notify     ← 02f00000-0000-0000-0000-00000000ff02
  //
  // Correct sequence:
  //   1. Subscribe ff02 for notifications
  //   2. Send initial probe to ff01: D2 03 00 00 00 7E 90 AA
  //   3. Send password to ff05: 48 69 4C 69 6E 6B ("HiLink")
  //   4. BMS sends 02 D2 00 00 on ff02 (auth confirmed)
  //   5. Send main data request to ff01: D2 03 00 80 00 70 74 B2
  //   6. BMS sends full data on ff02
  // ---------------------------------------------------------------------------

  // HiLink password bytes: ASCII "HiLink"
  static const List<int> _hiLinkPassword = [
    0x48, 0x69, 0x4C, 0x69, 0x6E, 0x6B,
  ];

  Future<void> _setupBmsSubscriptions(
      BluetoothDevice device, List<BluetoothService> services) async {
    final deviceId = device.remoteId.str;
    _authenticated[deviceId] = false;
    debugPrint('=== Setting up BMS for $deviceId ===');

    final allChars = services.expand((s) => s.characteristics).toList();
    _notifySubs[deviceId] = [];

    // ── Log all characteristics ──────────────────────────────────────────
    for (var svc in services) {
      debugPrint('Service: ${svc.uuid}');
      for (var ch in svc.characteristics) {
        debugPrint(
            '  [${_shortUuid(ch.uuid.toString())}] notify=${ch.properties.notify} '
            'write=${ch.properties.write} writeNoResp=${ch.properties.writeWithoutResponse}');
      }
    }

    // ── Find key characteristics ─────────────────────────────────────────
    BluetoothCharacteristic? ff01; // write Modbus commands
    BluetoothCharacteristic? ff02; // receive notifications
    BluetoothCharacteristic? ff04; // additional notify (fallback)
    BluetoothCharacteristic? ff05; // write password
    BluetoothCharacteristic? fff1; // some devices notify on FFF1
    BluetoothCharacteristic? fff2; // write on FFF service

    for (var ch in allChars) {
      final uuid = ch.uuid.toString().toLowerCase();
      if (uuid.endsWith('ff01')) ff01 ??= ch;
      if (uuid.endsWith('ff02')) ff02 ??= ch;
      if (uuid.endsWith('ff04')) ff04 ??= ch;
      if (uuid.endsWith('ff05')) ff05 ??= ch;
      if (uuid.endsWith('fff1')) fff1 ??= ch;
      if (uuid.endsWith('fff2')) fff2 ??= ch;
    }

    // ── Subscribe to ALL notify characteristics ──────────────────────────
    // ff02 is primary; also subscribe ff04, ff01 (if notify), fff1
    final notifyTargets = <BluetoothCharacteristic>[];
    if (ff02 != null) notifyTargets.add(ff02);
    if (ff04 != null &&
        (ff04.properties.notify || ff04.properties.indicate)) {
      notifyTargets.add(ff04);
    }
    if (fff1 != null &&
        (fff1.properties.notify || fff1.properties.indicate)) {
      notifyTargets.add(fff1);
    }
    // Fallback: subscribe to everything notifiable
    if (notifyTargets.isEmpty) {
      for (var ch in allChars) {
        if (ch.properties.notify || ch.properties.indicate) {
          notifyTargets.add(ch);
        }
      }
    }

    for (var ch in notifyTargets) {
      await _subscribeToChar(deviceId, ch);
    }

    // ── Set write characteristic (ff01 for data commands) ────────────────
    final writeChar = ff01 ??
        fff2 ??
        allChars
            .where(
                (c) => c.properties.write || c.properties.writeWithoutResponse)
            .firstOrNull;

    if (writeChar == null) {
      debugPrint('ERROR: No writable characteristic found!');
      _appendRawLog(deviceId, '[ERROR] No write char found!');
      return;
    }
    _writeCharacteristics[deviceId] = writeChar;

    // ── Set FFF2 as the DATA characteristic (Modbus data goes here) ──────
    // FFF2 is the DATA channel: send Modbus read commands here
    // FFF1 receives the data responses
    final dataChar = fff2 ??
        allChars
            .where((c) =>
                c.uuid.toString().toLowerCase().endsWith('fff2') &&
                (c.properties.write || c.properties.writeWithoutResponse))
            .firstOrNull ??
        writeChar; // ultimate fallback
    _dataCharacteristics[deviceId] = dataChar;

    // ── Set password characteristic (ff05) ───────────────────────────────
    final passChar = ff05 ?? writeChar;

    _appendRawLog(deviceId, '[SETUP] Auth-Write: ${_shortUuid(writeChar.uuid.toString())} (ff01)');
    _appendRawLog(deviceId, '[SETUP] Data-Write: ${_shortUuid(dataChar.uuid.toString())} (fff2)');
    _appendRawLog(deviceId, '[SETUP] Password:   ${_shortUuid(passChar.uuid.toString())} (ff05)');
    _appendRawLog(deviceId,
        '[SETUP] Notify: ${notifyTargets.map((c) => _shortUuid(c.uuid.toString())).join(", ")}');

    debugPrint('Auth=${writeChar.uuid}, Data=${dataChar.uuid}, Pass=${passChar.uuid}');

    // ── Step 1: Send initial probe to wake up BMS ────────────────────────
    try {
      final withoutResp = !writeChar.properties.write &&
          writeChar.properties.writeWithoutResponse;
      final probeHex = _modbusInitProbe
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      debugPrint('TX Probe [${writeChar.uuid}] => $probeHex');
      _appendRawLog(deviceId, '[TX-PROBE] $probeHex');
      await writeChar.write(_modbusInitProbe, withoutResponse: withoutResp);
    } catch (e) {
      debugPrint('Probe write error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // ── Step 2: Send HiLink password to ff05 ────────────────────────────
    await _sendHiLinkPassword(deviceId, passChar);

    // ── Step 3: Wait for BMS auth response (02 D2 00 00), then poll ──────
    // The periodic timer will check _authenticated flag
    // Also schedule a fallback send in case auth already happened
    await Future.delayed(const Duration(milliseconds: 800));

    // Try first data request (BMS may have already authenticated)
    await _sendModbusCommands(deviceId);

    // ── Step 4: Periodic poll every 3 seconds ────────────────────────────
    _queryTimers[deviceId]?.cancel();
    _queryTimers[deviceId] =
        Timer.periodic(const Duration(seconds: 3), (_) async {
      await _sendModbusCommands(deviceId);
    });
  }

  /// Subscribe to a single characteristic and wire up the RX handler
  Future<void> _subscribeToChar(
      String deviceId, BluetoothCharacteristic ch) async {
    try {
      await ch.setNotifyValue(true);
      final sub = ch.onValueReceived.listen((value) {
        if (value.isEmpty) return;
        final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        debugPrint('RX [${ch.uuid}] => $hex');
        _appendRawLog(deviceId, '[${_shortUuid(ch.uuid.toString())}] $hex');
        _onRxData(deviceId, value);
      });
      _notifySubs[deviceId]!.add(sub);
      debugPrint('Subscribed to ${ch.uuid}');
      _appendRawLog(deviceId, '[SETUP] Subscribed: ${_shortUuid(ch.uuid.toString())}');
    } catch (e) {
      debugPrint('Cannot subscribe to ${ch.uuid}: $e');
    }
  }

  String _shortUuid(String uuid) {
    return uuid.length >= 4 ? uuid.substring(uuid.length - 4) : uuid;
  }

  /// Sends the HiLink password to ff05 to authenticate with the BMS
  Future<void> _sendHiLinkPassword(
      String deviceId, BluetoothCharacteristic passChar) async {
    try {
      final withoutResponse = !passChar.properties.write &&
          passChar.properties.writeWithoutResponse;
      final pwHex =
          _hiLinkPassword.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      debugPrint('TX Password [${passChar.uuid}] => $pwHex ("HiLink")');
      _appendRawLog(deviceId,
          '[TX-AUTH→${_shortUuid(passChar.uuid.toString())}] $pwHex (HiLink)');
      await passChar.write(_hiLinkPassword, withoutResponse: withoutResponse);
      debugPrint('HiLink password sent to ${passChar.uuid}');
    } catch (e) {
      debugPrint('Error sending password: $e');
      _appendRawLog(deviceId, '[ERROR] Password failed: $e');
    }
  }

  /// Sends Modbus data request to FFF2 — responses come on FFF1
  Future<void> _sendModbusCommands(String deviceId) async {
    // Use FFF2 (data channel) not ff01 (auth channel)!
    final dataChar = _dataCharacteristics[deviceId];
    if (dataChar == null) return;

    final battery =
        state.connectedBatteries.where((b) => b.id == deviceId).firstOrNull;
    if (battery == null || battery.status != BatteryStatus.connected) return;

    try {
      final withoutResponse = !dataChar.properties.write &&
          dataChar.properties.writeWithoutResponse;

      // If we don't have the hardware/firmware details yet, fetch them first.
      // Once we have them, only fetch live telemetry data (address 0x0000).
      if (battery.hardwareVersion.isEmpty) {
        final cmdHex = _modbusRead62
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        debugPrint('TX-DATA [Config Address 0x0080] [${dataChar.uuid}] => $cmdHex');
        _appendRawLog(deviceId, '[TX-DATA→Config] $cmdHex');
        await dataChar.write(_modbusRead62, withoutResponse: withoutResponse);
      } else {
        final cmdHex = _modbusRead62From0
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        debugPrint('TX-DATA [Live Address 0x0000] [${dataChar.uuid}] => $cmdHex');
        _appendRawLog(deviceId, '[TX-DATA→Live] $cmdHex');
        await dataChar.write(_modbusRead62From0, withoutResponse: withoutResponse);
      }
    } catch (e) {
      debugPrint('Error sending data command to FFF2: $e');
      final fallbackCmd = battery.hardwareVersion.isEmpty ? _modbusRead62 : _modbusRead62From0;
      
      // Fallback: also try via ff01
      final writeChar = _writeCharacteristics[deviceId];
      if (writeChar != null) {
        try {
          final wr = !writeChar.properties.write &&
              writeChar.properties.writeWithoutResponse;
          final cmdHex = fallbackCmd.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          debugPrint('TX-DATA Fallback [${writeChar.uuid}] => $cmdHex');
          _appendRawLog(deviceId, '[TX-FALLBACK] $cmdHex');
          await writeChar.write(fallbackCmd, withoutResponse: wr);
        } catch (_) {}
      }
    }
  }

  // ---------------------------------------------------------------------------
  // RX Data Handler – accumulates bytes and parses Modbus RTU frames
  // ---------------------------------------------------------------------------
  void _onRxData(String deviceId, List<int> data) {
    final buf = _accumulators.putIfAbsent(deviceId, () => []);
    buf.addAll(data);

    // Try to parse as many complete Modbus RTU frames as possible
    while (buf.length >= 5) {
      // Find D2 03 header
      final startIdx = _findModbusStart(buf);
      if (startIdx == -1) {
        // No valid start found; discard all but last 3 bytes (could be partial header)
        if (buf.length > 3) {
          buf.removeRange(0, buf.length - 3);
        }
        break;
      }

      if (startIdx > 0) {
        buf.removeRange(0, startIdx);
        continue;
      }

      // buf[0] = 0xD2, buf[1] = 0x03, buf[2] = byte count
      final byteCount = buf[2];
      final frameLen = 3 + byteCount + 2; // header(3) + data + CRC(2)

      if (buf.length < frameLen) {
        break; // Wait for more data
      }

      final frame = buf.sublist(0, frameLen);

      // Validate CRC-16/Modbus
      if (_validateModbusCrc(frame)) {
        debugPrint(
            'Valid Modbus frame: ${frame.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
        _parseModbusResponse(deviceId, frame);
        buf.removeRange(0, frameLen);
      } else {
        // CRC mismatch – skip this byte and try again
        debugPrint('CRC mismatch, skipping byte: 0x${buf[0].toRadixString(16)}');
        buf.removeAt(0);
      }
    }
  }

  /// Finds the index of the first D2 03 sequence in buf, returns -1 if not found
  int _findModbusStart(List<int> buf) {
    for (int i = 0; i < buf.length - 1; i++) {
      if (buf[i] == 0xD2 && buf[i + 1] == 0x03) {
        return i;
      }
    }
    return -1;
  }

  /// Validates Modbus RTU CRC-16
  bool _validateModbusCrc(List<int> frame) {
    if (frame.length < 3) return false;
    final computed = _crc16(frame.sublist(0, frame.length - 2));
    final rxLo = frame[frame.length - 2];
    final rxHi = frame[frame.length - 1];
    return computed == ((rxHi << 8) | rxLo);
  }

  /// CRC-16/Modbus calculation
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

  // ---------------------------------------------------------------------------
  // Parse Modbus RTU response from DL-series BMS
  //
  // Frame format:
  //   [0]  0xD2      – Device address
  //   [1]  0x03      – Function code (read holding registers)
  //   [2]  byteCount – Number of data bytes following (N)
  //   [3..3+N-1]     – Register data (big-endian, 2 bytes per register)
  //   [3+N..3+N+1]   – CRC-16 (little-endian)
  //
  // ─── LIVE DATA Packet (anchor byte 0x75 at payload[82]) ───────────────────
  // This is the correct packet format confirmed from the SMART BMS app capture:
  //   D2 03 7C  (124 bytes = 62 registers)
  //
  // Example reference packet:
  //   D2 03 7C 0FCF 0FD3 ... (13 cell voltages @ 4.047–4.055V)
  //   ... 0000s ...
  //   0053 0054 0054 0054  ← Temp T1-T4 (raw-40 = °C, e.g. 83-40=43°C)
  //   00FF 00FF 00FF 00FF  ← Temp T5-T8 (0x00FF = sensor not installed)
  //   020E 7598 033D 0FD7 0FCF 0054 0053 0001 00F8 000D 0004 0020
  //   0000 0001 0001 0FD4 0008 022D 0000 0000 0000 0000
  //
  // LIVE DATA Register layout (payload byte offsets, big-endian 16-bit regs):
  //   offset  0–25  (13 regs): Cell voltages 1-13 in mV (e.g. 0x0FCF = 4047 mV)
  //   offset 26–63  (19 regs): Reserved / zeros
  //   offset 64–71  (4 regs) : Temp sensors T1-T4, raw value − 40 = °C
  //                            e.g. 0x0053=83 → 83−40=43°C
  //   offset 72–79  (4 regs) : Temp sensors T5-T8 (0x00FF = not installed)
  //   offset 80–81  (1 reg)  : Pack voltage, unit 0.1V → e.g. 0x020E=526 → 52.6V
  //   offset 82     (1 byte) : ANCHOR BYTE = 0x75 (identifies live data packet)
  //   offset 83     (1 byte) : Additional status byte
  //   offset 84–85  (1 reg)  : Remaining capacity, unit 0.1Ah → e.g. 0x033D=829 → 82.9Ah
  //   offset 86–87  (1 reg)  : Max cell voltage in mV
  //   offset 88–89  (1 reg)  : Min cell voltage in mV
  //   offset 90–91  (1 reg)  : SOC % (0–100)
  //   offset 92–93  (1 reg)  : SOH % (0–100)
  //   offset 94–95  (1 reg)  : Reserved/flags
  //   offset 96–97  (1 reg)  : Current, signed, unit 0.1A
  //                            positive = charging, negative = discharging
  //   offset 98–99  (1 reg)  : Temperature (most accurate sensor), unit 1°C
  //   offset 100–101(1 reg)  : Cycle count
  //   offset 102–103(1 reg)  : Full capacity, unit 0.1Ah
  //   offset 104–105(1 reg)  : Reserved
  //   offset 106–107(1 reg)  : Charge MOS status (1=ON, 0=OFF)
  //   offset 108–109(1 reg)  : Discharge MOS status (1=ON, 0=OFF)
  //   offset 110–111(1 reg)  : Average cell voltage in mV
  //   offset 112–113(1 reg)  : Cells in series count
  //   offset 114–115(1 reg)  : Design capacity, unit 0.1Ah
  //
  // ─── CONFIG/FIRMWARE Packet (no anchor, contains ASCII strings) ───────────
  // The BMS also sends a config response for a different register address.
  // These packets contain firmware strings like "WT00K_218042_11", "F903_E301_1.2H"
  // at payload offsets 80+. We detect and skip these – only live data matters.
  // ---------------------------------------------------------------------------
  void _parseModbusResponse(String deviceId, List<int> frame) {
    final existingIndex =
        state.connectedBatteries.indexWhere((b) => b.id == deviceId);
    if (existingIndex == -1) return;

    final b = state.connectedBatteries[existingIndex];
    final byteCount = frame[2];

    // Data payload starts at index 3
    final payload = frame.sublist(3, 3 + byteCount);

    debugPrint(
        'Parsing Modbus payload: $byteCount bytes (${byteCount ~/ 2} registers)');

    // ── CONFIG PACKET DETECTION & PROCESSING ─────────────────────────────────
    // Detect config packet by checking if bytes 81-82 contain the model prefix
    // (e.g. 'W' and 'T' for the "WT00K" model, or 'D' and 'L' for Daly models),
    // which starts at byte 81 following a null byte at byte 80.
    final isConfig = byteCount >= 120 &&
        payload[80] == 0x00 &&
        ((payload[81] == 0x57 && payload[82] == 0x54) || // 'W', 'T'
         (payload[81] == 0x44 && payload[82] == 0x4C));  // 'D', 'L'

    if (isConfig) {
      debugPrint('Processing config/firmware packet, byteCount=$byteCount');
      
      // Parse config ASCII fields
      String parseAscii(int start, int end) {
        if (end > payload.length) end = payload.length;
        if (start >= end) return '';
        final chunk = payload.sublist(start, end);
        final charCodes = chunk.where((b) => b >= 32 && b <= 126).toList();
        return String.fromCharCodes(charCodes).trim();
      }

      final hardware = parseAscii(80, 96);
      final firmware = parseAscii(96, 112);
      final date = parseAscii(112, 124);

      // Extract Design Capacity from Reg 0 (byte 0-1) and Cells in Series from Reg 3 (byte 6-7)
      final rawDesCap = (payload[0] << 8) | payload[1];
      final designCapacity = rawDesCap > 0 ? double.parse((rawDesCap / 10.0).toStringAsFixed(1)) : b.designCapacity;
      
      final rawCells = (payload[6] << 8) | payload[7];
      final cellsInSeries = rawCells > 0 ? rawCells : b.cellsInSeries;

      if (hardware.isNotEmpty || firmware.isNotEmpty || date.isNotEmpty) {
        debugPrint('Parsed Config: HW=$hardware, FW=$firmware, Date=$date, Cap=${designCapacity}Ah, Cells=${cellsInSeries}S');
        _appendRawLog(deviceId, '[CONFIG] HW: $hardware, FW: $firmware, Date: $date, Cap: ${designCapacity}Ah, Cells: ${cellsInSeries}S');
        
        state = state.copyWith(
          connectedBatteries: state.connectedBatteries.map((item) {
            if (item.id == deviceId) {
              return item.copyWith(
                hardwareVersion: hardware,
                firmwareVersion: firmware,
                manufactureDate: date,
                designCapacity: designCapacity,
                cellsInSeries: cellsInSeries,
              );
            }
            return item;
          }).toList(),
        );
      }
      return;
    }

    // Helper to read a big-endian 16-bit register from payload
    int reg(int byteOffset) {
      if (byteOffset + 1 >= payload.length) return 0;
      return (payload[byteOffset] << 8) | payload[byteOffset + 1];
    }

    // ── CELL VOLTAGES (bytes 0–25, 13 cells in mV) ───────────────────────────
    final List<int> cellVoltages = [];
    for (int i = 0; i < 13; i++) {
      final mv = reg(i * 2);
      if (mv > 1000 && mv < 5000) {
        // Valid cell voltage range (1V–5V)
        cellVoltages.add(mv);
      } else if (i < cellVoltages.length || cellVoltages.isNotEmpty) {
        // Stop reading cells once we hit an invalid value after valid ones
        break;
      }
    }
    debugPrint('Cell voltages: ${cellVoltages.map((v) => "${(v/1000).toStringAsFixed(3)}V").join(", ")}');

    // ── TEMPERATURE SENSORS (bytes 64–71, T1–T4, raw − 40 = °C) ─────────────
    // e.g. 0x0053 = 83 → 83 − 40 = 43°C
    // 0x00FF = sensor not installed
    double temperature = b.temperature;
    for (int i = 0; i < 4; i++) {
      final rawTemp = reg(64 + i * 2);
      if (rawTemp != 0x00FF && rawTemp > 0 && rawTemp < 200) {
        // Valid temperature sensor reading
        temperature = (rawTemp - 40).toDouble();
        break; // Use first valid sensor
      }
    }

    // ── PACK VOLTAGE (bytes 80–81, unit 0.1V) ────────────────────────────────
    // e.g. 0x020E = 526 → 52.6V
    double voltage = b.voltage;
    final rawVolt = reg(80);
    if (rawVolt > 0 && rawVolt < 10000) {
      voltage = double.parse((rawVolt / 10.0).toStringAsFixed(1));
    } else if (cellVoltages.isNotEmpty) {
      // Fallback: sum all valid cell voltages
      final sumMv = cellVoltages.fold<int>(0, (a, v) => a + v);
      voltage = double.parse((sumMv / 1000.0).toStringAsFixed(2));
    }

    // ── SOC % (bytes 84-85, unit 0.1%) ─────────────────────────────────────────
    double soc = b.soc;
    final rawSocVal = reg(84);
    if (rawSocVal > 0) {
      soc = double.parse((rawSocVal / 10.0).toStringAsFixed(1));
    }

    // ── CURRENT (bytes 82-83, signed current offset 30000, unit 0.1A) ──────────
    double current = b.current;
    final rawCurrentVal = reg(82);
    if (rawCurrentVal > 0) {
      current = double.parse(((rawCurrentVal - 30000) / 10.0).toStringAsFixed(1));
    }

    // ── REMAINING CAPACITY (bytes 96-97, unit 0.1Ah) ───────────────────────────
    double remainingCapacity = b.remainingCapacity;
    final rawRemCap = reg(96);
    if (rawRemCap > 0) {
      remainingCapacity = double.parse((rawRemCap / 10.0).toStringAsFixed(1));
    }

    // ── SOH % (bytes 90-91) ───────────────────────────────────────────────────
    int health = b.health;
    final rawSoh = reg(90);
    if (rawSoh >= 0 && rawSoh <= 100) {
      health = rawSoh;
    }

    // ── CYCLE COUNT (bytes 102-103) ───────────────────────────────────────────
    int cycles = b.cycleCount;
    final rawCycles = reg(102);
    if (rawCycles >= 0 && rawCycles < 50000) {
      cycles = rawCycles;
    }

    // ── CELLS IN SERIES (bytes 98-99) ─────────────────────────────────────────
    final cellsInSeries = reg(98) > 0 ? reg(98) : b.cellsInSeries;

    // ── MAX / MIN CELL VOLTAGE (bytes 86-87, 88-89, in mV) ────────────────────
    final maxCellMv = reg(86).toDouble();
    final minCellMv = reg(88).toDouble();

    // ── AVERAGE CELL VOLTAGE (bytes 110-111, in mV) ───────────────────────────
    final avgCellMv = reg(110).toDouble();

    // ── CHARGE / DISCHARGE MOS STATUS (bytes 106–107, 108–109) ──────────────
    final chargeMos = reg(106) == 1;
    final dischargeMos = reg(108) == 1;

    // ── VOLTAGE DIFFERENCE / POWER ────────────────────────────────────────────
    // reg(112) is voltage difference (Max - Min) in mV
    // reg(114) is real-time Power in Watts
    final voltDiffMv = reg(112);
    final rawPowerWatts = reg(114);
    
    // Design capacity remains unchanged from config packet
    double designCapacity = b.designCapacity;

    debugPrint('Parsed live data: '
        'SOC=$soc% SOH=$health% '
        'V=${voltage}V I=${current}A T=$temperature°C '
        'Cycles=$cycles Cells=${cellVoltages.length}x '
        'ChargeON=$chargeMos DischargeON=$dischargeMos '
        'Cap=$remainingCapacity/${designCapacity}Ah');

    // ── Voice Alert for 100% Fully Charged ─────────────────────────────────────
    if (soc >= 100.0) {
      if (!_voicedFullyCharged.contains(deviceId)) {
        _voicedFullyCharged.add(deviceId);
        _speakFullyCharged(b.name);
      }
    } else {
      _voicedFullyCharged.remove(deviceId);
    }

    // ── Update telemetry histories ─────────────────────────────────────────────
    final socHistory = [...b.socHistory, soc];
    if (socHistory.length > 30) socHistory.removeAt(0);

    final tempHistory = [...b.tempHistory, temperature];
    if (tempHistory.length > 30) tempHistory.removeAt(0);

    final voltHistory = [...b.voltHistory, voltage];
    if (voltHistory.length > 30) voltHistory.removeAt(0);

    final currentHistory = [...b.currentHistory, current];
    if (currentHistory.length > 30) currentHistory.removeAt(0);

    BatteryModel? updatedBattery;

    state = state.copyWith(
      connectedBatteries: state.connectedBatteries.map((item) {
        if (item.id == deviceId) {
          updatedBattery = item.copyWith(
            soc: soc,
            voltage: voltage,
            current: current,
            temperature: temperature,
            cycleCount: cycles,
            health: health,
            cellVoltages: cellVoltages,
            designCapacity: designCapacity,
            remainingCapacity: remainingCapacity,
            maxCellVoltage: maxCellMv,
            minCellVoltage: minCellMv,
            avgCellVoltage: avgCellMv,
            chargeMos: chargeMos,
            dischargeMos: dischargeMos,
            cellsInSeries: cellsInSeries > 0 ? cellsInSeries : item.cellsInSeries,
            socHistory: socHistory,
            tempHistory: tempHistory,
            voltHistory: voltHistory,
            currentHistory: currentHistory,
          );
          return updatedBattery!;
        }
        return item;
      }).toList(),
    );

    if (updatedBattery != null) {
      _syncTelemetryToBackend(updatedBattery!);
    }
  }

  Future<void> _speakFullyCharged(String batteryName) async {
    try {
      debugPrint("TTS speaking: Battery No. $batteryName is fully charged, please remove.");
      _addActivityLog('Alert: Battery $batteryName fully charged');
      await _tts.speak("Battery No. $batteryName is fully charged please remove");
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Disconnect
  // ---------------------------------------------------------------------------
  void _handleDisconnect(String batteryId) {
    _queryTimers[batteryId]?.cancel();
    _queryTimers.remove(batteryId);
    _writeCharacteristics.remove(batteryId);
    _accumulators.remove(batteryId);

    for (var sub in (_notifySubs[batteryId] ?? [])) {
      sub.cancel();
    }
    _notifySubs.remove(batteryId);

    final existingIndex =
        state.connectedBatteries.indexWhere((b) => b.id == batteryId);
    if (existingIndex != -1) {
      _addActivityLog(
          '${state.connectedBatteries[existingIndex].name} disconnected');
    }

    state = state.copyWith(
      connectedBatteries: state.connectedBatteries.map((b) {
        if (b.id == batteryId) return b.copyWith(status: BatteryStatus.disconnected);
        return b;
      }).toList(),
    );

    Timer(const Duration(seconds: 5), () {
      state = state.copyWith(
        connectedBatteries: state.connectedBatteries
            .where((b) =>
                !(b.id == batteryId && b.status == BatteryStatus.disconnected))
            .toList(),
      );
    });
  }

  Future<void> disconnectDevice(String id) async {
    final battery =
        state.connectedBatteries.firstWhere((b) => b.id == id);
    if (battery.device != null) {
      try {
        await battery.device!.disconnect();
      } catch (_) {
        _handleDisconnect(id);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Simulated battery (kept for demo purposes if needed)
  // ---------------------------------------------------------------------------
  void addSimulatedBattery(String name, double soc, double temp) {
    final id = 'sim_${DateTime.now().millisecondsSinceEpoch}';
    final double volt =
        double.parse((44.0 + (soc / 100.0) * 10.5).toStringAsFixed(1));
    final List<int> cells = List.generate(13, (i) {
      return ((volt / 13.0) * 1000 + _random.nextInt(20) - 10).round();
    });

    final battery = BatteryModel(
      id: id,
      name: name,
      soc: soc,
      temperature: temp,
      voltage: volt,
      current: -5.0,
      rssi: -60 - _random.nextInt(25),
      status: BatteryStatus.connected,
      isSimulated: true,
      cycleCount: 125,
      health: 98,
      cellVoltages: cells,
      socHistory: [soc, soc, soc],
      tempHistory: [temp, temp, temp],
      voltHistory: [volt, volt, volt],
      currentHistory: [-5.0, -5.0, -5.0],
    );
    
    state = state.copyWith(
        connectedBatteries: [...state.connectedBatteries, battery]);

    // Initial sync
    _syncTelemetryToBackend(battery);

    // Periodic fluctuation and sync
    _queryTimers[id]?.cancel();
    _queryTimers[id] = Timer.periodic(const Duration(seconds: 3), (_) {
      final existingIndex = state.connectedBatteries.indexWhere((b) => b.id == id);
      if (existingIndex == -1) return;

      final currentBat = state.connectedBatteries[existingIndex];

      // Fluctuate SOC down (simulating usage)
      double nextSoc = currentBat.soc - 0.2;
      if (nextSoc <= 0.0) {
        nextSoc = 100.0; // wrap around for continuous demo
      }
      nextSoc = double.parse(nextSoc.toStringAsFixed(1));

      // Fluctuate temperature
      double nextTemp = currentBat.temperature + (_random.nextDouble() * 0.4 - 0.2);
      if (nextTemp > 45.0) nextTemp = 35.0;
      if (nextTemp < 20.0) nextTemp = 25.0;
      nextTemp = double.parse(nextTemp.toStringAsFixed(1));

      // Calculate voltage based on SOC
      double nextVolt = double.parse((44.0 + (nextSoc / 100.0) * 10.5).toStringAsFixed(1));

      // Calculate current (small fluctuation around -5.0A)
      double nextCurrent = -4.5 - _random.nextDouble() * 1.5;
      nextCurrent = double.parse(nextCurrent.toStringAsFixed(1));

      // Cells voltage fluctuation
      final avgCellMv = (nextVolt / 13.0) * 1000;
      final List<int> nextCells = List.generate(13, (i) {
        return (avgCellMv + _random.nextInt(30) - 15).round();
      });

      final updated = currentBat.copyWith(
        soc: nextSoc,
        temperature: nextTemp,
        voltage: nextVolt,
        current: nextCurrent,
        cellVoltages: nextCells,
      );

      state = state.copyWith(
        connectedBatteries: state.connectedBatteries.map((b) => b.id == id ? updated : b).toList(),
      );

      _syncTelemetryToBackend(updated);
    });
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: '');
  }

  void triggerDemoVoiceAlert() {
    _speakFullyCharged("EVB2548");
  }

  void renameBattery(String id, String newName) {
    final existingIndex =
        state.connectedBatteries.indexWhere((b) => b.id == id);
    if (existingIndex != -1) {
      final oldName = state.connectedBatteries[existingIndex].name;
      _addActivityLog('Renamed $oldName to $newName');
    }
    state = state.copyWith(
      connectedBatteries: state.connectedBatteries.map((b) {
        if (b.id == id) return b.copyWith(name: newName);
        return b;
      }).toList(),
    );
  }

  void _addActivityLog(String message) {
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    state = state.copyWith(
      recentActivity: ['$message|$timeStr', ...state.recentActivity]
          .take(10)
          .toList(),
    );
  }

  void _appendRawLog(String deviceId, String entry) {
    final newLog = Map<String, List<String>>.from(state.rawDataLog);
    final existing = List<String>.from(newLog[deviceId] ?? []);
    existing.insert(0, entry); // newest first
    if (existing.length > 50) existing.removeLast();
    newLog[deviceId] = existing;
    state = state.copyWith(rawDataLog: newLog);
  }

  final Dio _dio = Dio();

  Future<void> _syncTelemetryToBackend(BatteryModel battery) async {
    try {
      double? lat;
      double? lng;
      try {
        final position = await LocationService.getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (e) {
        debugPrint('Error getting GPS: $e');
      }

      lat ??= 28.6304;
      lng ??= 77.2177;

      final data = {
        'battery_id': battery.id,
        'status': battery.status == BatteryStatus.connected
            ? (battery.current > 0 ? 'charging' : battery.current < 0 ? 'in_use' : 'idle')
            : (battery.status == BatteryStatus.faulty ? 'alert' : 'idle'),
        'soc': battery.soc.round(),
        'voltage': battery.voltage,
        'current': battery.current,
        'temp': battery.temperature,
        'cycles': battery.cycleCount,
        'health': battery.health,
        'lat': lat,
        'lng': lng,
        'cells': battery.cellVoltages,
      };

      debugPrint('Syncing telemetry: $data');
      await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.batteriesEndpoint}',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      debugPrint('Telemetry sync failed: $e');
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    for (var t in _queryTimers.values) {
      t.cancel();
    }
    for (var subs in _notifySubs.values) {
      for (var s in subs) {
        s.cancel();
      }
    }
    super.dispose();
  }
}
