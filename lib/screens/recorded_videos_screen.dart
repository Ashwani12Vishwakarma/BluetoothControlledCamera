import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bluetooth_controller.dart';

class RecordedVideosScreen extends StatefulWidget {
  const RecordedVideosScreen({super.key});

  @override
  State<RecordedVideosScreen> createState() => _RecordedVideosScreenState();
}

class _RecordedVideosScreenState extends State<RecordedVideosScreen> {
  final controller = Get.find<BluetoothController>();
  List<File> videoFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => isLoading = true);
    try {
      final folder = await controller.getPersistentVideoFolder();
      final items = folder
          .listSync()
          .where((item) => item is File && item.path.toLowerCase().endsWith('.mp4'))
          .cast<File>()
          .toList();

      // Sort by last modified date (newest first)
      items.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      setState(() {
        videoFiles = items;
      });
    } catch (e) {
      print("Error loading videos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _deleteVideo(File file) async {
    final confirmed = await Get.defaultDialog<bool>(
      title: "Delete Video",
      middleText: "Are you sure you want to delete this video file from this device?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirmed == true) {
      try {
        if (await file.exists()) {
          await file.delete();
          _loadVideos();
          Get.snackbar("Deleted", "Video deleted successfully", snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to delete file: $e", snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recorded Videos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          )
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : videoFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No videos found",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Recorded or received videos will appear here.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: videoFiles.length,
                    itemBuilder: (context, index) {
                      final file = videoFiles[index];
                      final name = file.path.split('/').last;
                      final stat = file.statSync();
                      final size = _formatFileSize(stat.size);
                      final date = _formatDateTime(stat.modified);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.blue,
                                size: 36,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "$size • $date",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteVideo(file),
                          ),
                          onTap: () => controller.playVideo(file.path),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}


