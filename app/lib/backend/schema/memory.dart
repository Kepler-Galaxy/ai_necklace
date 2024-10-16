import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/schema/geolocation.dart';
import 'package:foxxy_package/backend/schema/message.dart';
import 'package:foxxy_package/backend/schema/structured.dart';
import 'package:foxxy_package/backend/schema/transcript_segment.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateMemoryResponse {
  final List<ServerMessage> messages;
  final ServerMemory? memory;

  CreateMemoryResponse({required this.messages, required this.memory});

  factory CreateMemoryResponse.fromJson(Map<String, dynamic> json) {
    return CreateMemoryResponse(
      messages: ((json['messages'] ?? []) as List<dynamic>)
          .map((message) => ServerMessage.fromJson(message))
          .toList(),
      memory:
          json['memory'] != null ? ServerMemory.fromJson(json['memory']) : null,
    );
  }
}

enum MemorySource { friend, openglass, screenpipe, web_link }

class MemoryExternalData {
  final String text;

  MemoryExternalData({required this.text});

  factory MemoryExternalData.fromJson(Map<String, dynamic> json) =>
      MemoryExternalData(text: json['text'] ?? '');

  Map<String, dynamic> toJson() => {'text': text};
}

enum MemoryPostProcessingStatus {
  not_started,
  in_progress,
  completed,
  canceled,
  failed
}

enum MemoryPostProcessingModel { fal_whisperx, custom_whisperx }

class MemoryPostProcessing {
  final MemoryPostProcessingStatus status;
  final MemoryPostProcessingModel? model;
  final String? failReason;

  MemoryPostProcessing(
      {required this.status, required this.model, this.failReason});

  factory MemoryPostProcessing.fromJson(Map<String, dynamic> json) {
    return MemoryPostProcessing(
      status: MemoryPostProcessingStatus.values.asNameMap()[json['status']] ??
          MemoryPostProcessingStatus.in_progress,
      model: MemoryPostProcessingModel.values.asNameMap()[json['model']] ??
          MemoryPostProcessingModel.fal_whisperx,
      failReason: json['fail_reason'],
    );
  }

  toJson() => {
        'status': status.toString().split('.').last,
        'model': model.toString().split('.').last
      };
}

DateTime parseUtcToLocal(String dateString) {
  DateTime parsedDate = DateTime.parse(dateString);
  DateTime utcDateTime = DateTime.utc(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedDate.hour,
      parsedDate.minute,
      parsedDate.second,
      parsedDate.millisecond,
      parsedDate.microsecond);
  return utcDateTime.toLocal();
}

class ServerProcessingMemory {
  final String id;
  final DateTime createdAt;
  final DateTime? startedAt;

  ServerProcessingMemory({
    required this.id,
    required this.createdAt,
    this.startedAt,
  });

  factory ServerProcessingMemory.fromJson(Map<String, dynamic> json) {
    return ServerProcessingMemory(
      id: json['id'],
      createdAt: parseUtcToLocal(json['created_at']),
      startedAt: json['started_at'] != null
          ? parseUtcToLocal(json['started_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'started_at': startedAt?.toUtc().toIso8601String(),
    };
  }

  String getTag() {
    return 'Processing';
  }

  Color getTagTextColor() {
    return Colors.white;
  }

  Color getTagColor() {
    return Colors.grey.shade800;
  }
}

class UpdateProcessingMemoryResponse {
  final ServerProcessingMemory? result;

  UpdateProcessingMemoryResponse({required this.result});

  factory UpdateProcessingMemoryResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProcessingMemoryResponse(
      result: json['result'] != null
          ? ServerProcessingMemory.fromJson(json['result'])
          : null,
    );
  }
}

class MemoryExternalLink {
  final ExternalLinkDescription? externalLinkDescription;
  final WebContentResponse? webContentResponse;

  MemoryExternalLink({
    this.externalLinkDescription,
    this.webContentResponse,
  });

  factory MemoryExternalLink.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MemoryExternalLink();
    return MemoryExternalLink(
      externalLinkDescription: json['external_link_description'] != null
          ? ExternalLinkDescription.fromJson(json['external_link_description'])
          : null,
      webContentResponse: json['web_content_response'] != null
          ? WebContentResponse.fromJson(json['web_content_response'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'external_link_description': externalLinkDescription?.toJson(),
      'web_content_response': webContentResponse?.toJson(),
    };
  }
}

class ExternalLinkDescription {
  final String link;
  final Map<String, dynamic> metadata;

  ExternalLinkDescription({
    required this.link,
    required this.metadata,
  });

  factory ExternalLinkDescription.fromJson(Map<String, dynamic> json) {
    return ExternalLinkDescription(
      link: json['link'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'metadata': metadata,
    };
  }
}

class WebContentResponse {
  final bool success;
  final String title;
  final String mainContent;
  final String url;

  WebContentResponse({
    required this.success,
    required this.title,
    required this.mainContent,
    required this.url,
  });

  factory WebContentResponse.fromJson(Map<String, dynamic> json) {
    return WebContentResponse(
      success: json['success'],
      title: json['title'],
      mainContent: json['main_content'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'title': title,
      'main_content': mainContent,
      'url': url,
    };
  }
}

class ServerMemory {
  final String id;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  final Structured structured;
  final List<TranscriptSegment> transcriptSegments;
  final Geolocation? geolocation;
  final List<MemoryPhoto> photos;

  final MemoryExternalLink? externalLink;

  final List<PluginResponse> pluginsResults;
  final MemorySource? source;
  final String? language; // applies to Friend only

  final MemoryExternalData? externalIntegration;
  // MemoryPostProcessing? postprocessing;
  String? processingMemoryId;

  bool discarded;
  final bool deleted;

  // local failed memories
  final bool failed;
  int retries;

  ServerMemory({
    required this.id,
    required this.createdAt,
    required this.structured,
    this.startedAt,
    this.finishedAt,
    this.transcriptSegments = const [],
    this.pluginsResults = const [],
    this.geolocation,
    this.photos = const [],
    this.discarded = false,
    this.deleted = false,
    this.failed = false,
    this.retries = 0,
    this.source,
    this.language,
    this.externalIntegration,
    // this.postprocessing,
    this.processingMemoryId,
    this.externalLink,
  });

  factory ServerMemory.fromJson(Map<String, dynamic> json) {
    return ServerMemory(
      id: json['id'],
      createdAt: parseUtcToLocal(json['created_at']),
      structured: Structured.fromJson(json['structured']),
      startedAt: json['started_at'] != null
          ? parseUtcToLocal(json['started_at'])
          : null,
      finishedAt: json['finished_at'] != null
          ? parseUtcToLocal(json['finished_at'])
          : null,
      transcriptSegments: ((json['transcript_segments'] ?? []) as List<dynamic>)
          .map((segment) => TranscriptSegment.fromJson(segment))
          .toList(),
      pluginsResults: ((json['plugins_results'] ?? []) as List<dynamic>)
          .map((result) => PluginResponse.fromJson(result))
          .toList(),
      geolocation: json['geolocation'] != null
          ? Geolocation.fromJson(json['geolocation'])
          : null,
      photos: (json['photos'] as List<dynamic>)
          .map((photo) => MemoryPhoto.fromJson(photo))
          .toList(),
      discarded: json['discarded'] ?? false,
      source: json['source'] != null
          ? MemorySource.values.asNameMap()[json['source']]
          : MemorySource.friend,
      language: json['language'],
      deleted: json['deleted'] ?? false,
      failed: json['failed'] ?? false,
      retries: json['retries'] ?? 0,
      externalIntegration: json['external_data'] != null
          ? MemoryExternalData.fromJson(json['external_data'])
          : null,
      // postprocessing: json['postprocessing'] != null ? MemoryPostProcessing.fromJson(json['postprocessing']) : null,
      processingMemoryId: json['processing_memory_id'],
      externalLink: json['external_link'] != null
          ? MemoryExternalLink.fromJson(json['external_link'])
          : null,
    );
  }

  // bool isPostprocessing() {
  //   int createdSecondsAgo = DateTime.now().difference(createdAt).inSeconds;
  //   return (postprocessing?.status == MemoryPostProcessingStatus.not_started ||
  //           postprocessing?.status == MemoryPostProcessingStatus.in_progress) &&
  //       createdSecondsAgo < 120;
  // }

  // bool isReadyForTranscriptAssignment() {
  //   // TODO: only thing matters here, is if !isPostProcessing() and if we have audio file.
  //   return !discarded && !deleted && !failed && postprocessing?.status == MemoryPostProcessingStatus.completed;
  // }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'structured': structured.toJson(),
      'started_at': startedAt?.toUtc().toIso8601String(),
      'finished_at': finishedAt?.toUtc().toIso8601String(),
      'transcript_segments':
          transcriptSegments.map((segment) => segment.toJson()).toList(),
      'plugins_results':
          pluginsResults.map((result) => result.toJson()).toList(),
      'geolocation': geolocation?.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'discarded': discarded,
      'deleted': deleted,
      'source': source?.toString(),
      'language': language,
      'failed': failed,
      'retries': retries,
      'external_data': externalIntegration?.toJson(),
      // 'postprocessing': postprocessing?.toJson(),
      'processing_memory_id': processingMemoryId,
      'external_link': externalLink?.toJson(),
    };
  }

  String getTag() {
    if (source == MemorySource.screenpipe) return 'Screenpipe';
    if (source == MemorySource.openglass) return 'Openglass';
    if (failed) return 'Failed';
    if (discarded) return 'Discarded';
    return structured.category.substring(0, 1).toUpperCase() +
        structured.category.substring(1);
  }

  Color getTagTextColor() {
    if (source == MemorySource.screenpipe) return Colors.deepPurple;
    return Colors.white;
  }

  Color getTagColor() {
    if (source == MemorySource.screenpipe) return Colors.white;
    return Colors.grey.shade800;
  }

  VoidCallback? onTagPressed(BuildContext context) {
    if (source == MemorySource.screenpipe)
      return () => launchUrl(Uri.parse('https://screenpi.pe/'));
    if (failed) {
      return () => showDialog(
          builder: (c) => getDialog(
              context,
              () => Navigator.pop(context),
              () => Navigator.pop(context),
              'Failed Memory',
              'This memory failed to be created. Will be retried once you reopen the app.',
              singleButton: true,
              okButtonText: 'OK'),
          context: context);
    }
    return null;
  }

  String getTranscript({int? maxCount, bool generate = false}) {
    var transcript = TranscriptSegment.segmentsAsString(transcriptSegments,
        includeTimestamps: true);
    if (maxCount != null)
      transcript = transcript.substring(0, min(maxCount, transcript.length));
    try {
      return utf8.decode(transcript.codeUnits);
    } catch (e) {
      return transcript;
    }
  }
}
