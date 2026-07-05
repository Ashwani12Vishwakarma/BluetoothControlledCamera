import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/bluetooth_controller.dart';
import 'screens/home_screen.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
  // await requestPermissions();
  // await Permission.photos.request();
  // await Permission.videos.request();
  // await Permission.storage.request();
  Get.put(BluetoothController(), permanent: true);
  // Get.put(CameraControllerX(), permanent: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
