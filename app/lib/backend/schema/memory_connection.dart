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
    return MemoryConnectionNode(
      memoryId: json['memory_id'] as String? ?? '',
      explanation: json['explanation'] as String?,
      children: _parseChildren(json['children']),
      memory: json['memory'] != null ? ServerMemory.fromJson(json['memory'] as Map<String, dynamic>) : null,
    );
  }

  static List<MemoryConnectionNode> _parseChildren(dynamic childrenJson) {
    if (childrenJson == null) {
      return [];
    }
    if (childrenJson is! List) {
      print('Warning: children is not a List in MemoryConnectionNode.fromJson');
      return [];
    }
    return childrenJson
        .map((child) => child is Map<String, dynamic> 
            ? MemoryConnectionNode.fromJson(child)
            : null)
        .where((child) => child != null)
        .cast<MemoryConnectionNode>()
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
}