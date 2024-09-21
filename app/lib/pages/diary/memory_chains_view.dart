import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/memory.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:friend_private/pages/memory_detail/page.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/memory_provider.dart';

class MemoryChainsView extends StatelessWidget {
  final List<MemoryConnectionNode> forest;

  const MemoryChainsView({Key? key, required this.forest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memory Chains:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: forest.map((tree) => _buildTree(context, tree, 0)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTree(
      BuildContext context, MemoryConnectionNode node, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (level > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      node.explanation ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
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
            width: 200,
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
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  memory.structured.overview,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}