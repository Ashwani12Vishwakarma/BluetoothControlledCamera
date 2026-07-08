import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teleprompter_script.dart';
import 'dart:convert';

class ScriptController extends GetxController {
  var savedScripts = <TeleprompterScript>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadScripts();
  }

  Future<void> loadScripts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? scriptsJson = prefs.getString('teleprompter_scripts');
    if (scriptsJson != null) {
      final List<dynamic> decodedList = json.decode(scriptsJson);
      savedScripts.value = decodedList
          .map((item) => TeleprompterScript.fromMap(item))
          .toList();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mapList = savedScripts
        .map((s) => s.toMap())
        .toList();
    await prefs.setString('teleprompter_scripts', json.encode(mapList));
  }

  void addScript(String title, String content) {
    final newScript = TeleprompterScript(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
    );
    savedScripts.add(newScript);
    _saveToPrefs();
  }

  void updateScript(String id, String newTitle, String newContent) {
    final index = savedScripts.indexWhere((s) => s.id == id);
    if (index != -1) {
      savedScripts[index] = TeleprompterScript(
        id: id,
        title: newTitle,
        content: newContent,
      );
      _saveToPrefs();
    }
  }

  void deleteScript(String id) {
    savedScripts.removeWhere((s) => s.id == id);
    _saveToPrefs();
  }
}
