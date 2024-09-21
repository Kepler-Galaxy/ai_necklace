class ServerDiary {
  final String id;
  final String uid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? footprintJpeg;
  final String content;
  final List<String> memoryIds;
  final bool userDeleted;

  ServerDiary({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    this.footprintJpeg,
    required this.content,
    required this.memoryIds,
    this.userDeleted = false,
  });

  factory ServerDiary.fromJson(Map<String, dynamic> json) {
    return ServerDiary(
      id: json['id'],
      uid: json['uid'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      footprintJpeg: json['footprint_jpeg'],
      content: json['content'],
      memoryIds: List<String>.from(json['memory_ids']),
      userDeleted: json['user_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'footprint_jpeg': footprintJpeg,
      'content': content,
      'memory_ids': memoryIds,
      'user_deleted': userDeleted,
    };
  }
}
