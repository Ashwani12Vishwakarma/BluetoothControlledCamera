import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bluetooth_controller.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final controller = Get.find<BluetoothController>();

  @override
  void initState() {
    super.initState();
    controller.scan();
    controller.listenCommands();
    controller.autoReconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Remote Controller")),
      body: Stack(
        children: [
          Obx(
            () => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              controller.isConnected.value
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled,
                              color: controller.isConnected.value
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Card(
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                controller.isConnected.value
                                                ? Colors.green
                                                : Colors.red,
                                            child: Icon(
                                              controller.isConnected.value
                                                  ? Icons.bluetooth_connected
                                                  : Icons.bluetooth_disabled,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Connection Status",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(controller.status.value),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (!controller.isConnected.value)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text("Scan Nearby Devices"),
                        onPressed: () async {
                          if (!await controller.ensureLocationEnabled()) {
                            return;
                          }
                          await controller.startDiscovery();
                        },
                      ),

                    const SizedBox(height: 24),

                    if (!controller.isConnected.value) ...[
                      const SizedBox(height: 20),

                      const Text(
                        "Paired Devices",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...controller.devices.map((device) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth_connected),

                            title: Text(device["name"] ?? "Unknown"),

                            subtitle: Text(device["address"] ?? ""),

                            trailing: controller.isConnecting.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      await controller.connect(
                                        device["address"],
                                      );
                                    },
                                    child: const Text("Connect"),
                                  ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    if (!controller.isConnected.value) ...[
                      const SizedBox(height: 20),

                      const Text(
                        "Nearby Devices",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...controller.discoveredDevices
                          .where((device) => device["bonded"] != true)
                          .map((device) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.devices),

                                title: Text(device["name"]),

                                subtitle: Text(device["address"]),

                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    await controller.pair(device["address"]);
                                  },

                                  child: const Text("Pair"),
                                ),
                              ),
                            );
                          }),
                    ],

                    const SizedBox(height: 24),

                    if (controller.isConnected.value)
                      Card(
                        margin: const EdgeInsets.only(top: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                controller.isRecording.value
                                    ? "🔴 Recording"
                                    : "⚪ Ready",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                controller.recordingTime.value,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    controller.isRecording.value
                                        ? Icons.stop
                                        : Icons.fiber_manual_record,
                                  ),
                                  label: Text(
                                    controller.isRecording.value
                                        ? "Stop Recording"
                                        : "Start Recording",
                                  ),
                                  onPressed: () {
                                    controller.send(
                                      controller.isRecording.value
                                          ? "STOP"
                                          : "START",
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    controller.isFlashOn.value
                                        ? Icons.flash_off
                                        : Icons.flash_on,
                                  ),
                                  label: Text(
                                    controller.isFlashOn.value
                                        ? "Flash OFF"
                                        : "Flash ON",
                                  ),
                                  onPressed: () {
                                    controller.send(
                                      controller.isFlashOn.value
                                          ? "FLASH_OFF"
                                          : "FLASH_ON",
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    controller.selectedCamera.value == 0
                                        ? Icons.camera_front
                                        : Icons.camera_rear,
                                  ),
                                  label: Text(
                                    controller.selectedCamera.value == 0
                                        ? "Switch to Front Camera"
                                        : "Switch to Rear Camera",
                                  ),
                                  onPressed: controller.isRecording.value
                                      ? null
                                      : () {
                                          if (controller.selectedCamera.value ==
                                              0) {
                                            controller.send("CAMERA_FRONT");
                                          } else {
                                            controller.send("CAMERA_REAR");
                                          }
                                        },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            if (!controller.isConnecting.value) {
              return const SizedBox();
            }

            return Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),

                        SizedBox(height: 20),

                        Text(
                          "Connecting to device...",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
