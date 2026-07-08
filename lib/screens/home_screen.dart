import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/bluetooth_controller.dart';
import 'receiver_screen.dart';
import 'remote_screen.dart';
import 'recorded_videos_screen.dart';
import 'scripts_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final bluetooth = Get.find<BluetoothController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Camera Remote"),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: "Teleprompter Scripts",
            onPressed: () => Get.to(() => const ScriptsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.video_library),
            tooltip: "Recorded Media",
            onPressed: () => Get.to(() => const RecordedVideosScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.bluetooth_connected,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 15),
              const Text(
                "Bluetooth Camera Recorder",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Control another Android phone over Bluetooth",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Receiver Card
              SizedBox(
                height: 260,
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Colors.blue,
                        ),
                        const Text(
                          "Camera Device",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Receive Bluetooth commands and record video remotely.",
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {

                              final enabled = await bluetooth
                                  .ensureBluetoothEnabled();
                              if (!enabled) {
                                Get.snackbar(
                                  "Bluetooth Required",
                                  "Turn on bluetooth first",
                                );
                                return;
                              }

                              final camera = await Permission.camera.request();
                              final mic = await Permission.microphone.request();

                              await Permission.videos.request();
                              await Permission.storage.request();

                              if (camera.isGranted && mic.isGranted) {
                                Get.to(() => const ReceiverScreen());
                              } else {
                                Get.snackbar(
                                  "Permission Required",
                                  "Camera and microphone permissions are required.",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                            child: const Text("Open Receiver"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Remote Card
              SizedBox(
                height: 260,
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Icon(
                          Icons.gamepad,
                          size: 60,
                          color: Colors.green,
                        ),
                        const Text(
                          "Remote Controller",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Connect to another device and control recording remotely.",
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final enabled = await bluetooth.ensureBluetoothEnabled();

                              if (!enabled) {
                                Get.snackbar(
                                  "Bluetooth Required",
                                  "Turn on bluetooth first",
                                );
                                return;
                              }
                              await Permission.bluetoothScan.request();
                              await Permission.bluetoothConnect.request();
                              await Permission.location.request();

                              Get.to(() => const RemoteScreen());
                            },
                            child: const Text("Open Remote"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
