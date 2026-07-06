import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_service.dart';
import '../screens/recorded_videos_screen.dart';

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

  RxBool isTransferring = false.obs;
  RxInt transferProgress = 0.obs;
  RxString transferStatus = "".obs;

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

      if (cmd.startsWith("FILE_TRANSFER_START|")) {
        final parts = cmd.split("|");
        isTransferring.value = true;
        transferProgress.value = 0;
        transferStatus.value = "Receiving video file: ${parts.length > 1 ? parts[1] : ''}...";
        return;
      } else if (cmd.startsWith("FILE_TRANSFER_PROGRESS|")) {
        final parts = cmd.split("|");
        if (parts.length > 1) {
          transferProgress.value = int.tryParse(parts[1]) ?? 0;
          transferStatus.value = "Receiving: ${transferProgress.value}%";
        }
        return;
      } else if (cmd.startsWith("FILE_TRANSFER_COMPLETE|")) {
        final parts = cmd.split("|");
        isTransferring.value = false;
        transferProgress.value = 100;
        transferStatus.value = "Received video file successfully";
        if (parts.length > 1) {
          final localPath = parts[1];
          _saveReceivedVideo(localPath);
        }
        return;
      } else if (cmd.startsWith("FILE_TRANSFER_FAILED|")) {
        final parts = cmd.split("|");
        isTransferring.value = false;
        transferStatus.value = "Transfer failed";
        Get.snackbar(
          "Error",
          "Video transfer failed: ${parts.length > 1 ? parts[1] : ''}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      } else if (cmd.startsWith("SEND_PROGRESS|")) {
        final parts = cmd.split("|");
        if (parts.length > 1) {
          isTransferring.value = true;
          transferProgress.value = int.tryParse(parts[1]) ?? 0;
          transferStatus.value = "Sending video: ${transferProgress.value}%";
        }
        return;
      } else if (cmd == "DISCONNECTED") {
        isConnected.value = false;
        status.value = "Disconnected";
        isTransferring.value = false;
        return;
      } else if (cmd == "CONNECTED") {
        isConnected.value = true;
        status.value = "Connected";
        return;
      }

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

  Future<bool> ensureLocationEnabled() async {
    final permission = await Permission.location.request();

    if (!permission.isGranted) {
      Get.snackbar(
        "Location Permission",
        "Please allow Location permission.",
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    final enabled = await service.isLocationEnabled();

    if (!enabled) {
      Get.defaultDialog(
        title: "Location Required",
        middleText:
            "Nearby Bluetooth scanning requires Location Services to be enabled.",
        textConfirm: "Open Settings",
        textCancel: "Cancel",
        onConfirm: () async {
          Get.back();
          await service.openLocationSettings();
        },
      );

      return false;
    }

    return true;
  }

  Future<bool> ensureBluetoothEnabled() async {
    final connect = await Permission.bluetoothConnect.request();

    if (!connect.isGranted) {
      Get.snackbar(
        "Permission Required",
        "Bluetooth Connect permission is required.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (await service.isBluetoothEnabled()) {
      return true;
    }

    await service.enableBluetooth();

    return false;
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

  Future<void> sendFile(String filePath) async {
    isTransferring.value = true;
    transferProgress.value = 0;
    transferStatus.value = "Sending video...";

    try {
      final success = await service.sendFile(filePath);
      if (success) {
        Get.snackbar(
          "Success",
          "Video sent successfully",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to send video",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("SEND FILE ERROR: $e");
    } finally {
      isTransferring.value = false;
    }
  }

  /// Returns the persistent folder for recorded videos.
  /// Uses external app-private storage so media players can open files directly.
  Future<Directory> getPersistentVideoFolder() async {
    // getExternalStorageDirectory() → /sdcard/Android/data/<pkg>/files/
    // Files here are accessible by external media players via file:// URI.
    Directory? extDir = await getExternalStorageDirectory();
    extDir ??= await getApplicationDocumentsDirectory(); // fallback
    final videoDir = Directory('${extDir.path}/recorded_videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  Future<String> saveVideoToPersistentStorage(String tempPath) async {
    try {
      final videoDir = await getPersistentVideoFolder();
      final fileName = tempPath.split('/').last;
      final newPath = '${videoDir.path}/$fileName';
      final file = File(tempPath);
      if (await file.exists()) {
        await file.copy(newPath);
        print("Copied video to persistent path: $newPath");
        return newPath;
      }
    } catch (e) {
      print("Error saving video persistently: $e");
    }
    return tempPath;
  }

  /// Opens the video file using the platform's default video player app.
  Future<void> playVideo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Get.snackbar(
          "File Not Found",
          "The video file could not be found.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final result = await OpenFile.open(filePath, type: "video/mp4");
      if (result.type != ResultType.done) {
        Get.snackbar(
          "Playback Error",
          result.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print("PLAY VIDEO ERROR: $e");
      Get.snackbar(
        "Error",
        "Could not open video: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveReceivedVideo(String localPath) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putVideo(localPath);

      // Copy the file to local persistent storage for the list screen
      final persistentPath = await saveVideoToPersistentStorage(localPath);

      // Show the choice dialog to the user on the Remote Controller
      Get.dialog(
        AlertDialog(
          title: const Text("Video Received"),
          content: const Text(
            "The recorded video has been successfully transferred to this device. What would you like to do?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                playVideo(persistentPath);
              },
              child: const Text("Play Video"),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => const RecordedVideosScreen());
              },
              child: const Text("Show All Videos"),
            ),
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      print("SAVE VIDEO ERROR: $e");
      Get.snackbar(
        "Save Failed",
        "Failed to save video: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}
