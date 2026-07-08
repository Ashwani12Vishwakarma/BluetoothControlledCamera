import 'dart:convert';

class TeleprompterScript {
  final String id;
  final String title;
  final String content;

  TeleprompterScript({
    required this.id,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }

  factory TeleprompterScript.fromMap(Map<String, dynamic> map) {
    return TeleprompterScript(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory TeleprompterScript.fromJson(String source) => TeleprompterScript.fromMap(json.decode(source));
}
