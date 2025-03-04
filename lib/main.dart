import 'package:bluetooth_app/core/bluetooth/bluetooth_manager.dart';
import 'package:bluetooth_app/core/database/database.dart';
import 'package:bluetooth_app/features/tag_management/repository/tag_repository.dart';
import 'package:bluetooth_app/test/ble/viewmodel/test_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'package:bluetooth_app/features/home/viewmodel/home_viewmodel.dart';
import 'features/tag_management/viewmodel/tag_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화

  //  BluetoothManager 인스턴스 생성 (싱글턴 사용)
  final bluetoothManager = BluetoothManager();
  bluetoothManager.setLoggingEnabled(true);

  // 데이터베이스 인스턴스 생성
  final database = await AppDatabase.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => bluetoothManager), // BluetoothManager 주입
        Provider(create: (_) => database),
        ChangeNotifierProvider(
            create: (context) =>
                HomeViewModel(context.read<BluetoothManager>())),
        ChangeNotifierProvider(
            create: (context) => TagViewModel(
                  context.read<BluetoothManager>(),
                  context.read<TagRepository>(),
                )),
        ChangeNotifierProvider(
            create: (context) =>
                BleTestViewModel(context.read<BluetoothManager>())),
      ],
      child: App(),
    ),
  );
}
