import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/camera_controller.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final controller = Get.find<BluetoothController>();
  final cameraController = Get.put(CameraControllerX());
  Worker? commandWorker;

  @override
  void initState() {
    super.initState();

    // cameraController.resetCamera();

    controller.onCommand = (command) async {
      print("COMMAND CALLBACK: $command");

      if (command == "START") {
        await cameraController.startRecording();
      } else if (command == "STOP") {
        final filePath = await cameraController.stopRecording();
        if (filePath != null) {
          controller.sendFile(filePath);
        }
      } else if (command == "FLASH_ON") {
        await cameraController.flashOn();
      } else if (command == "FLASH_OFF") {
        await cameraController.flashOff();
      } else if (command == "CAMERA_FRONT") {
        await cameraController.switchCamera(true);
      } else if (command == "CAMERA_REAR") {
        await cameraController.switchCamera(false);
      }
    };

    controller.startServer();
    controller.listenCommands();
    if (!cameraController.isInitialized.value) {
      cameraController.initCamera();
    }
  }

  @override
  void dispose() {
    Get.delete<CameraControllerX>();
    commandWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receiver Device")),
      body: Obx(() {
        if (!cameraController.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: controller.isConnected.value
                                  ? Colors.green
                                  : Colors.orange,
                              child: Icon(
                                controller.isConnected.value
                                    ? Icons.bluetooth_connected
                                    : Icons.bluetooth_searching,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Bluetooth Status",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),

                                  Text(controller.status.value),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CameraPreview(cameraController.cameraController!),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              cameraController.isRecording.value
                                  ? "🔴 RECORDING"
                                  : "⚪ READY",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              cameraController.formattedTime,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Divider(),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Last Command",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),

                                Text(
                                  controller.lastCommand.value.isEmpty
                                      ? "--"
                                      : controller.lastCommand.value,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isTransferring.value)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            controller.transferStatus.value,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: controller.transferProgress.value / 100.0,
                          ),
                          const SizedBox(height: 8),
                          Text("${controller.transferProgress.value}%"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
