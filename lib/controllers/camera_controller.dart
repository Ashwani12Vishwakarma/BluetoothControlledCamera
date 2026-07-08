import 'dart:async';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'bluetooth_controller.dart';
// import 'dart:io';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';

class CameraControllerX extends GetxController {
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  int currentCameraIndex = 0;

  RxBool isInitialized = false.obs;
  RxBool isRecording = false.obs;
  RxInt seconds = 0.obs;

  bool _isInitializing = false;

  Timer? timer;

  Future<void> initCamera() async {
    if (_isInitializing) {
      print("Camera already initializing");
      return;
    }

    try {
      _isInitializing = true;

      cameras = await availableCameras();

      print("Total cameras: ${cameras.length}");

      for (final c in cameras) {
        print("Available Direction: ${c.lensDirection}");
      }

      currentCameraIndex = 0;

      cameraController = CameraController(
        cameras[currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await cameraController!.initialize();

      isInitialized.value = true;

      print("CAMERA INITIALIZED");
    } catch (e) {
      print("INIT CAMERA ERROR: $e");
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> resetCamera() async {
    try {
      print("RESET CAMERA CALLED");

      if (_isInitializing) {
        print("Skip reset, camera busy");
        return;
      }

      timer?.cancel();

      if (cameraController != null) {
        try {
          await cameraController!.dispose();
        } catch (e) {
          print("Dispose error: $e");
        }
        cameraController = null;
      }

      isInitialized.value = false;
      isRecording.value = false;
      seconds.value = 0;

      await Future.delayed(const Duration(milliseconds: 500));

      await initCamera();

      print("CAMERA RESET DONE");
    } catch (e) {
      print("RESET CAMERA ERROR: $e");
    }
  }

  Future<void> startRecording() async {
    try {
      print("START RECORDING CALLED");

      if (cameraController == null) {
        print("cameraController null");
        return;
      }

      print("isRecording=${cameraController!.value.isRecordingVideo}");

      if (cameraController!.value.isRecordingVideo) {
        print("Already recording");
        return;
      }

      await cameraController!.startVideoRecording();

      print("VIDEO RECORDING STARTED");

      isRecording.value = true;
      startTimer();
    } catch (e, s) {
      print("START RECORD ERROR: $e");
      print(s);
    }
  }

  Future<String?> stopRecording() async {
    try {
      print("STOP RECORDING CALLED");

      if (cameraController == null) return null;

      if (!cameraController!.value.isRecordingVideo) {
        print("Not recording");
        return null;
      }

      final recordedFile = await cameraController!.stopVideoRecording();


      print("Recorded temp file: ${recordedFile.path}");

      await Gal.putVideo(recordedFile.path);

      print("VIDEO SAVED TO GALLERY");


      timer?.cancel();
      seconds.value = 0;
      isRecording.value = false;

      // Copy the recorded file persistently on the Receiver device as well
      final btController = Get.find<BluetoothController>();
      final persistentPath = await btController.saveMediaToPersistentStorage(recordedFile.path);

      return persistentPath;
    } catch (e) {
      print("STOP ERROR: $e");
      return null;
    }
  }

  void startTimer() {
    timer?.cancel();
    seconds.value = 0;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds.value++;
    });
  }

  Future<String?> captureImage() async {
    try {
      print("CAPTURE IMAGE CALLED");

      if (cameraController == null) return null;
      if (cameraController!.value.isRecordingVideo) {
        print("Cannot capture image while recording");
        return null;
      }

      final xFile = await cameraController!.takePicture();
      print("Captured image: ${xFile.path}");

      await Gal.putImage(xFile.path);
      print("IMAGE SAVED TO GALLERY");

      final btController = Get.find<BluetoothController>();
      final persistentPath = await btController.saveMediaToPersistentStorage(xFile.path);

      return persistentPath;
    } catch (e) {
      print("CAPTURE IMAGE ERROR: $e");
      return null;
    }
  }

  Future<void> flashOn() async {
    await cameraController?.setFlashMode(FlashMode.torch);
  }

  Future<void> flashOff() async {
    await cameraController?.setFlashMode(FlashMode.off);
  }

  Future<void> switchCamera(bool useFront) async {
    try {
      if (cameraController?.value.isRecordingVideo == true) {
        Get.snackbar(
          "Camera Switch",
          "Stop recording before switching cameras.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final index = useFront ? 1 : 0;

      if (index >= cameras.length) {
        Get.snackbar(
          "Camera Switch",
          "Requested camera not available.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (currentCameraIndex == index) {
        return;
      }

      isInitialized.value = false;

      await cameraController?.dispose();

      currentCameraIndex = index;

      cameraController = CameraController(
        cameras[currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await cameraController!.initialize();

      isInitialized.value = true;

      print("Camera switched successfully.");
    } catch (e) {
      isInitialized.value = true;
      print("SWITCH ERROR: $e");
    }
  }


  @override
  void onClose() {
    timer?.cancel();
    cameraController?.dispose();
    super.onClose();
  }

  String get formattedTime {
    final min = (seconds.value ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds.value % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }
  
}
