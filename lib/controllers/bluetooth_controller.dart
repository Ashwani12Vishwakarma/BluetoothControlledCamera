import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_service.dart';

class BluetoothController extends GetxController {
  final BluetoothService service = BluetoothService();
  RxString lastCommand = "".obs;
  RxInt receiverBattery = 0.obs;

  RxBool isConnected = false.obs;
  RxBool isConnecting = false.obs;
  RxBool isRecording = false.obs;
  RxBool isFlashOn = false.obs;
  RxString recordingTime = "00:00".obs;
  RxInt selectedCamera = 0.obs;

  // 0 = Rear
  // 1 = Front

  RxString status = "Disconnected".obs;
  RxList devices = [].obs;

  Timer? recordingTimer;
  int seconds = 0;

  RxList<Map<String, dynamic>> discoveredDevices = <Map<String, dynamic>>[].obs;

  Function(String command)? onCommand;

  void listenCommands() {
    service.commandStream().listen((event) {
      print("RAW EVENT: $event");

      if (event is Map) {
        if (event["type"] == "device") {
          final address = event["address"];

          final index = discoveredDevices.indexWhere(
            (d) => d["address"] == address,
          );

          if (index >= 0) {
            discoveredDevices[index] = Map<String, dynamic>.from(event);
          } else {
            discoveredDevices.add(Map<String, dynamic>.from(event));
          }

          return;
        }
      }

      final cmd = event.toString().trim();

      status.value = "Connected";
      isConnected.value = true;
      lastCommand.value = cmd;

      switch (cmd) {
        case "START":
          isRecording.value = true;
          break;

        case "STOP":
          isRecording.value = false;
          Get.snackbar(
            "Success",
            "Video saved successfully",
            snackPosition: SnackPosition.BOTTOM,
          );
          break;

        case "FLASH_ON":
          isFlashOn.value = true;
          break;

        case "FLASH_OFF":
          isFlashOn.value = false;
          break;
      }

      onCommand?.call(cmd);
    });
  }

  Future<void> startDiscovery() async {
    discoveredDevices.clear();
    await service.startDiscovery();
  }

  Future<void> scan() async {
    try {
      status.value = "Scanning paired devices...";

      final result = await service.scanDevices();

      devices.value = result;

      status.value = result.isEmpty
          ? "No paired devices found"
          : "Paired devices loaded";
    } catch (e) {
      status.value = "Scan failed";
      print("SCAN ERROR: $e");
    }
  }

  Future<void> startServer() async {
    status.value = await service.startServer();
  }

  Future<void> connect(String address) async {
    if (isConnecting.value) return;

    try {
      isConnecting.value = true;
      status.value = "🔄 Connecting...";

      final result = await service.connect(address);

      if (result == "Connected") {
        isConnected.value = true;
        status.value = "🟢 Connected";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("last_device", address);
      } else {
        isConnected.value = false;
        status.value = "🔴 Connection Failed";
      }
    } catch (e) {
      isConnected.value = false;
      status.value = "⚪ Disconnected";
      print(e);
    } finally {
      isConnecting.value = false;
    }
  }

  Future<bool> ensureBluetoothEnabled() async {
    final enabled = await service.isBluetoothEnabled();

    if (enabled) {
      return true;
    }

    await service.enableBluetooth();

    await Future.delayed(const Duration(seconds: 2));

    return await service.isBluetoothEnabled();
  }

  Future<bool> checkBluetooth() async {
    final enabled = await service.isBluetoothEnabled();

    if (!enabled) {
      Get.snackbar(
        "Bluetooth Off",
        "Please enable Bluetooth first.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return enabled;
  }

  Future<void> send(String cmd) async {
    final success = await service.sendCommand(cmd);

    if (!success) {
      Get.snackbar(
        "Connection Lost",
        "Unable to send command",
        snackPosition: SnackPosition.BOTTOM,
      );

      isConnected.value = false;
      status.value = "Disconnected";

      return;
    }

    switch (cmd) {
      case "START":
        isRecording.value = true;
        _startTimer();

        break;

      case "STOP":
        isRecording.value = false;
        _stopTimer();

        Get.snackbar(
          "Success",
          "Video saved successfully",
          snackPosition: SnackPosition.BOTTOM,
        );

        break;

      case "FLASH_ON":
        isFlashOn.value = true;

        break;

      case "FLASH_OFF":
        isFlashOn.value = false;

        break;

      case "CAMERA_FRONT":
        selectedCamera.value = 1;
        break;

      case "CAMERA_REAR":
        selectedCamera.value = 0;
        break;
    }
  }

  void _startTimer() {
    recordingTimer?.cancel();

    seconds = 0;
    recordingTime.value = "00:00";

    recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;

      final min = (seconds ~/ 60).toString().padLeft(2, '0');
      final sec = (seconds % 60).toString().padLeft(2, '0');

      recordingTime.value = "$min:$sec";
    });
  }

  void _stopTimer() {
    recordingTimer?.cancel();

    recordingTime.value = "00:00";
  }

  Future<void> autoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString("last_device");

    if (address == null) {
      status.value = "No previous device";
      return;
    }

    status.value = "Reconnecting...";
    await connect(address);
  }

  Future<void> pair(String address) async {
    try {
      status.value = "Pairing...";

      await service.pairDevice(address);

      status.value = "Waiting for pairing confirmation...";

      // Give Android time to complete pairing
      await Future.delayed(const Duration(seconds: 5));

      // Refresh paired devices
      await scan();

      // Clear old discovery results
      discoveredDevices.clear();

      // Start a fresh scan
      await startDiscovery();

      status.value = "Pairing complete";
    } catch (e) {
      status.value = "Pairing failed";
      print("PAIR ERROR: $e");
    }
  }
}
