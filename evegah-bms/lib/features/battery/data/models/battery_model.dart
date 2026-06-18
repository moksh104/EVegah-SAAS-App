import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BatteryStatus {
  disconnected,
  connecting,
  connected,
  faulty,
}

class BatteryModel {
  final String id; // MAC address or UUID
  final String name; // Name of the battery, e.g., BOS001 or DL-411912010860
  final double soc; // State of Charge (0-100)
  final double temperature; // Temperature in Celsius
  final double voltage; // Voltage in Volts
  final double current; // Amperage in Amps (positive for charging, negative for discharging)
  final int rssi; // Signal strength in dBm
  final BatteryStatus status;
  final bool isSimulated;
  final BluetoothDevice? device;
  
  // Cycle count and SOH Health data
  final int cycleCount;
  final int health; // State of Health (0-100)

  // Per-cell voltages in mV (up to 16 cells)
  final List<int> cellVoltages;

  // Additional BMS fields from live data packet
  final double designCapacity;    // Design capacity in Ah
  final double remainingCapacity; // Remaining capacity in Ah
  final double maxCellVoltage;    // Max cell voltage in mV
  final double minCellVoltage;    // Min cell voltage in mV
  final double avgCellVoltage;    // Avg cell voltage in mV
  final bool chargeMos;           // Charge MOSFET status
  final bool dischargeMos;        // Discharge MOSFET status
  final int cellsInSeries;        // Number of cells in series

  // Hardware version, firmware version, and manufacture date from config packet
  final String hardwareVersion;
  final String firmwareVersion;
  final String manufactureDate;

  // Real-time telemetry history lists for rendering charts
  final List<double> socHistory;
  final List<double> tempHistory;
  final List<double> voltHistory;
  final List<double> currentHistory;

  const BatteryModel({
    required this.id,
    required this.name,
    required this.soc,
    required this.temperature,
    required this.voltage,
    required this.current,
    required this.rssi,
    required this.status,
    this.isSimulated = false,
    this.device,
    this.cycleCount = 120,
    this.health = 98,
    this.cellVoltages = const [],
    this.designCapacity = 0.0,
    this.remainingCapacity = 0.0,
    this.maxCellVoltage = 0.0,
    this.minCellVoltage = 0.0,
    this.avgCellVoltage = 0.0,
    this.chargeMos = false,
    this.dischargeMos = false,
    this.cellsInSeries = 0,
    this.hardwareVersion = '',
    this.firmwareVersion = '',
    this.manufactureDate = '',
    this.socHistory = const [],
    this.tempHistory = const [],
    this.voltHistory = const [],
    this.currentHistory = const [],
  });

  BatteryModel copyWith({
    String? id,
    String? name,
    double? soc,
    double? temperature,
    double? voltage,
    double? current,
    int? rssi,
    BatteryStatus? status,
    bool? isSimulated,
    BluetoothDevice? device,
    int? cycleCount,
    int? health,
    List<int>? cellVoltages,
    double? designCapacity,
    double? remainingCapacity,
    double? maxCellVoltage,
    double? minCellVoltage,
    double? avgCellVoltage,
    bool? chargeMos,
    bool? dischargeMos,
    int? cellsInSeries,
    String? hardwareVersion,
    String? firmwareVersion,
    String? manufactureDate,
    List<double>? socHistory,
    List<double>? tempHistory,
    List<double>? voltHistory,
    List<double>? currentHistory,
  }) {
    return BatteryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      soc: soc ?? this.soc,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      rssi: rssi ?? this.rssi,
      status: status ?? this.status,
      isSimulated: isSimulated ?? this.isSimulated,
      device: device ?? this.device,
      cycleCount: cycleCount ?? this.cycleCount,
      health: health ?? this.health,
      cellVoltages: cellVoltages ?? this.cellVoltages,
      designCapacity: designCapacity ?? this.designCapacity,
      remainingCapacity: remainingCapacity ?? this.remainingCapacity,
      maxCellVoltage: maxCellVoltage ?? this.maxCellVoltage,
      minCellVoltage: minCellVoltage ?? this.minCellVoltage,
      avgCellVoltage: avgCellVoltage ?? this.avgCellVoltage,
      chargeMos: chargeMos ?? this.chargeMos,
      dischargeMos: dischargeMos ?? this.dischargeMos,
      cellsInSeries: cellsInSeries ?? this.cellsInSeries,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      socHistory: socHistory ?? this.socHistory,
      tempHistory: tempHistory ?? this.tempHistory,
      voltHistory: voltHistory ?? this.voltHistory,
      currentHistory: currentHistory ?? this.currentHistory,
    );
  }
}
