import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/memory.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:friend_private/pages/memory_detail/page.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/memory_provider.dart';
import 'package:friend_private/pages/memory_detail/memory_detail_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friend_private/generated/l10n.dart';
import 'package:collection/collection.dart';

class FlashingBoltIcon extends StatefulWidget {
  const FlashingBoltIcon({Key? key}) : super(key: key);

  @override
  _FlashingBoltIconState createState() => _FlashingBoltIconState();
}

class _FlashingBoltIconState extends State<FlashingBoltIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(Icons.bolt, size: 30, color: Colors.yellow),
        );
      },
    );
  }
}

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (connectedMemories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              S.current.DiaryMemoryConnectionText,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          ...connectedMemories
              .expand((node) => [
                    _buildTree(context, node, 0),
                    SizedBox(height: 24), // Increased vertical spacing
                  ])
              .toList(),
          SizedBox(height: 32), // Larger spacer between sections
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              S.current.DiaryNoConnectedMemory,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
        if (unconnectedMemories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              S.current.DiarySeparateMemoryText,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          ...unconnectedMemories
              .expand((node) => [
                    _buildTree(context, node, 0),
                    SizedBox(height: 24), // Increased vertical spacing
                  ])
              .toList(),
        ],
      ],
    );
  }

  Widget _buildTree(
      BuildContext context, MemoryConnectionNode node, int level) {
    return node.children.isEmpty
        ? _buildLeafNode(context, node, level)
        : _buildBranchNode(context, node, level);
  }

  Widget _buildLeafNode(
      BuildContext context, MemoryConnectionNode node, int level) {
    return Padding(
      padding: EdgeInsets.only(left: level * 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (level > 0) _buildConnectionIndicator(context, node),
              Expanded(child: _buildMemoryNode(context, node.memoryId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchNode(
      BuildContext context, MemoryConnectionNode node, int level) {
    return Padding(
      padding: EdgeInsets.only(left: level * 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (level > 0) _buildConnectionIndicator(context, node),
              Expanded(child: _buildMemoryNode(context, node.memoryId)),
            ],
          ),
          ...node.children
              .map((child) => _buildTree(context, child, level + 1)),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(
      BuildContext context, MemoryConnectionNode node) {
    return Container(
      width: 35,
      child: Column(
        children: [
          if (node.explanation != null && node.explanation!.isNotEmpty)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                      backgroundColor: Colors.black,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10.0,
                              offset: const Offset(0.0, 10.0),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              S.current.ExplanationText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              node.explanation!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 24),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                child: Text(
                                  S.current.ExplanationClose,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: FlashingBoltIcon(),
            )
        ],
      ),
    );
  }

  Widget _buildMemoryNode(BuildContext context, String memoryId) {
    return FutureBuilder<ServerMemory?>(
      key: ValueKey(memoryId),
      future: _getOrFetchMemory(context, memoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          debugPrint('Error loading memory $memoryId: ${snapshot.error}');
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          debugPrint('No data for memory $memoryId');
          return Text('Memory not found');
        }

        ServerMemory memory = snapshot.data!;
        return GestureDetector(
          onTap: () {
            // TODO(yiqi): This memoryDetailProvider index mechanism is badly designed.
            // Need to refactor with memory provider fetching mechanism together.
            final memoryDetailProvider =
                Provider.of<MemoryDetailProvider>(context, listen: false);
            final memoryProvider =
                Provider.of<MemoryProvider>(context, listen: false);
            int idx = memoryProvider.memoriesWithDates.indexWhere((e) {
              if (e.runtimeType == ServerMemory) {
                return e.id == memory.id;
              }
              return false;
            });
            memoryDetailProvider.updateMemory(idx);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemoryDetailPage(
                  key: ValueKey(memory.id),
                  memory: memory,
                  isPopup: true,
                ),
              ),
            );
          },
          child: Container(
            width: 250,
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
                  maxLines: 3,
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

  Future<ServerMemory?> _getOrFetchMemory(
      BuildContext context, String memoryId) async {
    final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);

    // Check if the memory already exists in the provider
    ServerMemory? existingMemory = memoryProvider.memories
        .whereType<ServerMemory>() // This filters out DateTime objects
        .firstWhereOrNull((m) => m.id == memoryId);
    if (existingMemory != null) return existingMemory;

    // If not found, fetch the memory
    ServerMemory? fetchedMemory = await memoryProvider.getMemoryById(memoryId);
    memoryProvider.addMemoryWithDate(fetchedMemory!);
    return fetchedMemory;
  }
}
