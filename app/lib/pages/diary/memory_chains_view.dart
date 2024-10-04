import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/memory.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:friend_private/pages/memory_detail/page.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/memory_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friend_private/generated/l10n.dart';

class MemoryChainsView extends StatelessWidget {
  final List<MemoryConnectionNode> forest;

  const MemoryChainsView({Key? key, required this.forest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<MemoryConnectionNode> connectedMemories = [];
    List<MemoryConnectionNode> unconnectedMemories = [];

    // Separate the memories into two groups
    for (var node in forest) {
      if (node.children.isNotEmpty) {
        connectedMemories.add(node);
      } else {
        unconnectedMemories.add(node);
      }
    }

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (connectedMemories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              S.current.DiaryMemoryConnectionText,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          ...connectedMemories.map((node) => _buildTree(context, node, 0)),
          SizedBox(height: 20), // Spacer between sections
        ]
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              S.current.DiaryNoConnectedMemory,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
        if (unconnectedMemories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              S.current.DiarySeparateMemoryText,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          ...unconnectedMemories.map((node) => _buildTree(context, node, 0)),
        ],
      ],
    );
  }

  // TODO(yiqi): Improve the layout.
  Widget _buildTree(BuildContext context, MemoryConnectionNode node, int level) {
    if (node.children.isEmpty) {
      return _buildLeafNode(context, node, level);
    } else {
      return _buildBranchNode(context, node, level);
    }
  }

  Widget _buildLeafNode(BuildContext context, MemoryConnectionNode node, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (level > 0)
              _buildConnectionIndicator(context, node),
            _buildMemoryNode(context, node.memoryId),
          ],
        ),
      ],
    );
  }

  Widget _buildBranchNode(BuildContext context, MemoryConnectionNode node, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (level > 0)
              _buildConnectionIndicator(context, node),
            _buildMemoryNode(context, node.memoryId),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map((child) => _buildTree(context, child, level + 1))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator(BuildContext context, MemoryConnectionNode node) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          SizedBox(height: 20),
          if (node.explanation != null &&
              node.explanation!.isNotEmpty)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Explanation'),
                      content: Text(node.explanation!),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Close'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.bolt, size: 16, color: Colors.blue),
            )
          else
            SizedBox(width: 16), // Placeholder for alignment
          Icon(Icons.arrow_downward, size: 16),
        ],
      ),
    );
  }

  Widget _buildMemoryNode(BuildContext context, String memoryId) {
    return FutureBuilder<ServerMemory?>(
      future: Provider.of<MemoryProvider>(context, listen: false)
          .getMemoryById(memoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Text('Error loading memory');
        }

        ServerMemory memory = snapshot.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MemoryDetailPage(memory: memory, isPopup: true),
              ),
            );
          },
          child: Container(
            width: 300,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.structured.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  memory.structured.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
