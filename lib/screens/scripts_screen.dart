import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/script_controller.dart';
import '../models/teleprompter_script.dart';
import 'script_preview_screen.dart';

class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({super.key});

  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  final ScriptController scriptData = Get.find<ScriptController>();

  void _showAddEditDialog([TeleprompterScript? script]) {
    final titleController = TextEditingController(text: script?.title ?? '');
    final contentController = TextEditingController(text: script?.content ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(script == null ? "Add New Script" : "Edit Script"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: "Script", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final t = titleController.text.trim();
              final c = contentController.text.trim();
              if (t.isNotEmpty && c.isNotEmpty) {
                if (script == null) {
                  scriptData.addScript(t, c);
                } else {
                  scriptData.updateScript(script.id, t, c);
                }
                Get.back();
              } else {
                Get.snackbar("Error", "Fields cannot be empty");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Scripts")),
      body: Obx(() {
        if (scriptData.savedScripts.isEmpty) {
          return const Center(child: Text("No saved scripts. Add one below."));
        }
        return ListView.builder(
          itemCount: scriptData.savedScripts.length,
          itemBuilder: (context, index) {
            final script = scriptData.savedScripts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(script.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(script.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  // Return the selected script back to RemoteScreen
                  Get.back(result: script);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                      tooltip: "Preview",
                      onPressed: () {
                        Get.to(() => ScriptPreviewScreen(script: script));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      tooltip: "Edit",
                      onPressed: () => _showAddEditDialog(script),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Delete",
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Delete Script",
                          middleText: "Are you sure you want to delete '${script.title}'?",
                          textConfirm: "Delete",
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.red,
                          textCancel: "Cancel",
                          onConfirm: () {
                            scriptData.deleteScript(script.id);
                            Get.back();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
