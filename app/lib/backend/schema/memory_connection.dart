class MemoryConnectionNode {
  final String memoryId;
  final String? explanation;
  final List<MemoryConnectionNode> children;

  MemoryConnectionNode({
    required this.memoryId,
    this.explanation,
    required this.children,
  });

  static MemoryConnectionNode fromJson(Map<String, dynamic> json) {
    return MemoryConnectionNode(
      memoryId: json['memory_id'],
    explanation: json['explanation'],
    children: (json['children'] as List).map((child) => MemoryConnectionNode.fromJson(child)).toList(),
  );
}
}