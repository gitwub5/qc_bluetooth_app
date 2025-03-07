import 'package:bluetooth_app/core/bluetooth/utils/ble_command.dart';
import 'package:bluetooth_app/shared/enums/command_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import '../../../shared/models/tag_model.dart';
import 'package:bluetooth_app/core/bluetooth/bluetooth_manager.dart';
import 'package:bluetooth_app/features/tag_management/repository/tag_repository.dart';

class TagViewModel extends ChangeNotifier {
  final BluetoothManager _bluetoothManager;
  final TagRepository _tagRepository;
  List<TagModel> tags = [];
  bool isLoading = false;

  List<fb.ScanResult> scanResults = [];
  bool isScanning = false;

  List<String> receivedDataList = [];

  TagViewModel(this._bluetoothManager, this._tagRepository) {
    // Bluetooth 상태 변화 감지하여 UI 업데이트
    _bluetoothManager.stateService.setBluetoothStateListener((state) {
      notifyListeners(); // UI 업데이트
    });

    // TX 데이터 구독
    _bluetoothManager.connectionService.txStream.listen((data) {
      _handleReceivedData(data);
    });

    loadTags();
  }

  /// BLE에서 받은 데이터 처리 (여기에는 성공 여부말곤 데이터 받을게 없음 저장할 필요 없음)
  void _handleReceivedData(String data) {
    receivedDataList.add(data);
    notifyListeners();
    print("📥 BLE 데이터 추가됨: $data");
  }

  Future<void> loadTags() async {
    final tagList = await _tagRepository.fetchTags();
    tags = tagList
        .map((tag) => TagModel(
              remoteId: tag['remoteId'],
              name: tag['name'],
              period: Duration(seconds: tag['sensor_period']),
              lastUpdated: DateTime.parse(tag['updated_at']),
              fridgeName: "Unknown",
            ))
        .toList();
    notifyListeners();
  }

  Future<void> addTag(
      String remoteId, String name, Duration period, DateTime updatedAt) async {
    await _tagRepository.addTag(remoteId, name, period, updatedAt);
    await loadTags();
  }

  Future<void> deleteTag(int id) async {
    await _tagRepository.deleteTag(id);
    await loadTags();
  }

  void toggleSelection(int index) {
    tags[index].isSelected = !tags[index].isSelected;
    notifyListeners();
  }

  void removeSelectedTags() {
    tags.removeWhere((tag) => tag.isSelected);
    notifyListeners();
  }

  /// ✅ 블루투스 장치 검색 시작 (로딩 상태 추가)
  Future<void> startScan() async {
    try {
      isScanning = true;
      scanResults.clear();
      notifyListeners();

      scanResults = await _bluetoothManager.scanService.scanDevices();

      isScanning = false;
      notifyListeners();
    } catch (e) {
      isScanning = false;
      notifyListeners();
      print("❌ Bluetooth Scan Failed: $e");
    }
  }

  Future<bool> connectToDevice(fb.BluetoothDevice device) async {
    try {
      await _bluetoothManager.connectionService.connectToDevice(device);
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Connection failed: $e");
      return false;
    }
  }

  Future<void> disconnectDevice() async {
    try {
      await _bluetoothManager.connectionService.disconnectDevice();
      receivedDataList.clear();
      print("🔌 Device disconnected.");
    } catch (e) {
      print("❌ Disconnection failed: $e");
    }
    notifyListeners();
  }

  /// ✅ BLE 장치로 데이터 쓰기
  Future<void> writeData(CommandType commandType,
      {DateTime? latestTime, Duration? period, String? name}) async {
    try {
      final command = BluetoothCommand(
        commandType: commandType,
        latestTime: latestTime,
        period: period,
        name: name,
      );

      String data = command.toJsonString();

      await _bluetoothManager.connectionService.writeCharacteristic(data);

      print("📤 Sent Data: $data");
    } catch (e) {
      print("❌ Write failed: $e");
    }
  }
}
