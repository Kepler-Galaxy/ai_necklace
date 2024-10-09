class ServerDiary {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool userDeleted;
  
  final DiaryConfig config;
  final DiaryUserConfig? userConfig;
  final DiaryDescription description;
  final DiaryContent content;

  ServerDiary({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.userDeleted = false,
    required this.config,
    this.userConfig,
    required this.description,
    required this.content,
  });

  factory ServerDiary.fromJson(Map<String, dynamic> json) {
    return ServerDiary(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userDeleted: json['user_deleted'] ?? false,
      config: DiaryConfig.fromJson(json['config']),
      userConfig: json['user_config'] != null ? DiaryUserConfig.fromJson(json['user_config']) : null,
      description: DiaryDescription.fromJson(json['description']),
      content: DiaryContent.fromJson(json['content']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_deleted': userDeleted,
      'config': config.toJson(),
      'user_config': userConfig?.toJson(),
      'description': description.toJson(),
      'content': content.toJson(),
    };
  }

  Map<String, dynamic> toAnalyticsJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_deleted': userDeleted,
      'config': config.toJson(),
      'user_config': userConfig?.toJson(),
      'description': description.toJson(),
    };
  }
}

class DiaryConfig {
  final String uid;
  final DateTime diaryStartUtc;
  final DateTime diaryEndUtc;

  DiaryConfig({
    required this.uid,
    required this.diaryStartUtc,
    required this.diaryEndUtc,
  });

  factory DiaryConfig.fromJson(Map<String, dynamic> json) {
    return DiaryConfig(
      uid: json['uid'],
      diaryStartUtc: DateTime.parse(json['diary_start_utc']),
      diaryEndUtc: DateTime.parse(json['diary_end_utc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'diary_start_utc': diaryStartUtc.toIso8601String(),
      'diary_end_utc': diaryEndUtc.toIso8601String(),
    };
  }
}

class DiaryUserConfig {
  final List<String> memoryIdsToAdd;
  final List<String> memoryIdsToRemove;
  final List<String> diaryIdsToAdd;
  final List<String> diaryIdsToRemove;

  DiaryUserConfig({
    required this.memoryIdsToAdd,
    required this.memoryIdsToRemove,
    required this.diaryIdsToAdd,
    required this.diaryIdsToRemove,
  });

  factory DiaryUserConfig.fromJson(Map<String, dynamic> json) {
    return DiaryUserConfig(
      memoryIdsToAdd: List<String>.from(json['memory_ids_to_add']),
      memoryIdsToRemove: List<String>.from(json['memory_ids_to_remove']),
      diaryIdsToAdd: List<String>.from(json['diary_ids_to_add']),
      diaryIdsToRemove: List<String>.from(json['diary_ids_to_remove']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_ids_to_add': memoryIdsToAdd,
      'memory_ids_to_remove': memoryIdsToRemove,
      'diary_ids_to_add': diaryIdsToAdd,
      'diary_ids_to_remove': diaryIdsToRemove,
    };
  }
}

class DiaryDescription {
  final List<String> memoryIds;
  final List<String> referenceMemoryIds;
  final List<String> referenceDiaryIds;

  DiaryDescription({
    required this.memoryIds,
    required this.referenceMemoryIds,
    required this.referenceDiaryIds,
  });

  factory DiaryDescription.fromJson(Map<String, dynamic> json) {
    return DiaryDescription(
      memoryIds: List<String>.from(json['memory_ids']),
      referenceMemoryIds: List<String>.from(json['reference_memory_ids']),
      referenceDiaryIds: List<String>.from(json['reference_diary_ids']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_ids': memoryIds,
      'reference_memory_ids': referenceMemoryIds,
      'reference_diary_ids': referenceDiaryIds,
    };
  }
}

class DiaryContent {
  final String? footprintJpeg;
  final String content;

  DiaryContent({
    this.footprintJpeg,
    required this.content,
  });

  factory DiaryContent.fromJson(Map<String, dynamic> json) {
    return DiaryContent(
      footprintJpeg: json['footprint_jpeg'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'footprint_jpeg': footprintJpeg,
      'content': content,
    };
  }
}
