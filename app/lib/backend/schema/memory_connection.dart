import 'package:friend_private/backend/schema/memory.dart';

class MemoryConnectionNode {
  final String memoryId;
  final String? explanation;
  final List<MemoryConnectionNode> children;
  final ServerMemory? memory;

  MemoryConnectionNode({
    required this.memoryId,
    this.explanation,
    required this.children,
    this.memory,
  });

  static MemoryConnectionNode fromJson(Map<String, dynamic> json) {
    ServerMemory? parsedMemory;
    if (json['memory'] != null) {
      try {
        parsedMemory = ServerMemory.fromJson(json['memory'] as Map<String, dynamic>);
      } catch (e) {
        // some old memory's format maybe inconsistent
        print('Error parsing memory: $e');
      }
    }

    return MemoryConnectionNode(
      memoryId: json['memory_id'] as String? ?? '',
      explanation: json['explanation'] as String?,
      children: _parseChildren(json['children']),
      memory: parsedMemory,
    );
  }

  static List<MemoryConnectionNode> _parseChildren(dynamic childrenJson) {
    if (childrenJson == null || childrenJson.isEmpty) {
      return [];
    }
    if (childrenJson is! List) {
      print('Warning: children is not a List in MemoryConnectionNode.fromJson');
      return [];
    }
    return childrenJson
        .where((child) => child is Map<String, dynamic>)
        .map((child) => MemoryConnectionNode.fromJson(child as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_id': memoryId,
      'explanation': explanation,
      'children': children.map((child) => child.toJson()).toList(),
      'memory': memory?.toJson(),
    };
  }

  Map<String, dynamic> toAnalyticsJson() {
    return {
      'memory_id': memoryId,
      'explanation': explanation,
      'children': children.map((child) => child.toAnalyticsJson()).toList(),
    };
  }
}