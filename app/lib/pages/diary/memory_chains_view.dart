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
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.current.MemoryChains + ":",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: forest.length,
          itemBuilder: (context, index) => _buildTree(context, forest[index], 0),
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // TODO(yiqi): Improve the layout.
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
                    Icon(Icons.arrow_downward, size: 16), // Changed to arrow_downward
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
