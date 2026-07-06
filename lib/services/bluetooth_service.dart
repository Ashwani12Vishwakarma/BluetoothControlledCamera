import 'package:flutter/services.dart';

class BluetoothService {
  static const MethodChannel _channel = MethodChannel("bluetooth_channel");
  static const EventChannel _eventChannel = EventChannel("bluetooth_events");

  Stream<dynamic> commandStream() {
    return _eventChannel.receiveBroadcastStream();
  }

  Future<String> startServer() async {
    return await _channel.invokeMethod("startServer");
  }

  Future<List<dynamic>> scanDevices() async {
    return await _channel.invokeMethod("scanDevices");
  }

  Future<void> startDiscovery() async {
    await _channel.invokeMethod("startDiscovery");
  }

  Future<String> connect(String address) async {
    return await _channel.invokeMethod("connect", {"address": address});
  }

  Future<bool> sendCommand(String cmd) async {
    try {
      final result = await _channel.invokeMethod("sendCommand", {
        "command": cmd,
      });

      return result == true;
    } catch (e) {
      print("SEND ERROR: $e");
      return false;
    }
  }

  Future<bool> sendFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod("sendFile", {
        "filePath": filePath,
      });
      return result == true;
    } catch (e) {
      print("SEND FILE ERROR: $e");
      return false;
    }
  }

  Future<void> enableBluetooth() async {
    await _channel.invokeMethod("enableBluetooth");
  }

  Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod("isBluetoothEnabled");
  }

  Future<bool> pairDevice(String address) async {
    final result = await _channel.invokeMethod("pairDevice", {
      "address": address,
    });
    return result;
  }

  Future<void> openLocationSettings() async {
    await _channel.invokeMethod("openLocationSettings");
  }

  Future<bool> isLocationEnabled() async {
    return await _channel.invokeMethod("isLocationEnabled");
  }

  Future<void> playVideo(String filePath) async {
    try {
      await _channel.invokeMethod("playVideo", {"filePath": filePath});
    } catch (e) {
      print("PLAY VIDEO ERROR: $e");
    }
  }
}
