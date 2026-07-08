import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/camera_controller.dart';
import '../controllers/teleprompter_controller.dart';
import '../models/teleprompter_script.dart';

class ScriptPreviewScreen extends StatefulWidget {
  final TeleprompterScript script;
  const ScriptPreviewScreen({super.key, required this.script});

  @override
  State<ScriptPreviewScreen> createState() => _ScriptPreviewScreenState();
}

class _ScriptPreviewScreenState extends State<ScriptPreviewScreen> {
  final cameraController = Get.put(CameraControllerX());
  final prompterController = Get.put(TeleprompterController());

  @override
  void initState() {
    super.initState();
    if (!cameraController.isInitialized.value) {
      cameraController.initCamera();
    }
    prompterController.setScript(widget.script.title, widget.script.content);
    // Don't auto-play right away, let user hit play if they want, but let's activate it.
    prompterController.isActive.value = true;
    
    // Auto play for preview? Let's just start it.
    // prompterController.play();
  }

  @override
  void dispose() {
    prompterController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Preview"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () {
              // Toggle front/rear camera for preview if they want
              // Not strictly necessary but nice to have
              if (cameraController.cameraController?.description.lensDirection == CameraLensDirection.front) {
                cameraController.switchCamera(false);
              } else {
                cameraController.switchCamera(true);
              }
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Live Camera Preview
          Obx(() {
            if (!cameraController.isInitialized.value || cameraController.cameraController == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController.cameraController!.value.previewSize?.height ?? 1,
                  height: cameraController.cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(cameraController.cameraController!),
                ),
              ),
            );
          }),

          // 2. Teleprompter Overlay
          Obx(() {
            if (!prompterController.isActive.value) return const SizedBox();

            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
              color: Colors.black.withValues(alpha: 0.4),
              child: SingleChildScrollView(
                controller: prompterController.scrollController,
                physics: const NeverScrollableScrollPhysics(), // Controlled by timer
                child: Column(
                  children: [
                    Text(
                      prompterController.title.value,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                        height: 1.2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      prompterController.text.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 800), // padding at bottom to scroll past screen
                  ],
                ),
              ),
            );
          }),

          // 3. Play/Pause Overlay Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: "preview_record",
                        backgroundColor: cameraController.isRecording.value ? Colors.red : Colors.grey[800],
                        onPressed: () async {
                          if (cameraController.isRecording.value) {
                            await cameraController.stopRecording();
                            Get.snackbar(
                              "Saved",
                              "Video saved to gallery",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            await cameraController.startRecording();
                          }
                        },
                        child: Icon(cameraController.isRecording.value ? Icons.stop : Icons.fiber_manual_record, color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: "preview_play",
                        backgroundColor: prompterController.isPlaying.value ? Colors.orange : Colors.green,
                        onPressed: () {
                          if (prompterController.isPlaying.value) {
                            prompterController.pause();
                          } else {
                            prompterController.play();
                          }
                        },
                        child: Icon(prompterController.isPlaying.value ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: "preview_reset",
                        backgroundColor: Colors.blue,
                        onPressed: () {
                          prompterController.pause();
                          if (prompterController.scrollController.hasClients) {
                            prompterController.scrollController.jumpTo(0);
                          }
                        },
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Speed", style: TextStyle(color: Colors.white)),
                        Slider(
                          value: prompterController.scrollSpeed.value,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: prompterController.scrollSpeed.value.toStringAsFixed(1),
                          onChanged: (val) {
                            prompterController.setSpeed(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
