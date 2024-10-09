import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:friend_private/generated/l10n.dart';
import 'package:friend_private/pages/diary/memory_chains_view.dart';
import 'package:friend_private/backend/schema/diary.dart';

class DiaryTabView extends StatelessWidget {
  final List<MemoryConnectionNode> forest;
  final ServerDiary? currentDateDiary;

  const DiaryTabView({
    Key? key,
    required this.forest,
    required this.currentDateDiary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Text(
                  S.current.MemoryChains,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Tab(
                child: Text(
                  S.current.MemoryContents,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          // TODO(yiqi): Bug. This expanded compete with the homepage TabBar setting. Which results in the 
          // content is blocked by that TarBar. I don't know how to fix.
          Expanded(
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildMemoryChainsTab(),
                _buildDiaryContentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryChainsTab() {
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (connectedMemories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
              child: Text(
                S.current.DiaryMemoryConnectionText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => MemoryChainsView(node: connectedMemories[index]),
              childCount: connectedMemories.length,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
        ] else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
              child: Text(
                S.current.DiaryNoConnectedMemory,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        if (unconnectedMemories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
              child: Text(
                S.current.DiarySeparateMemoryText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => MemoryChainsView(node: unconnectedMemories[index]),
              childCount: unconnectedMemories.length,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiaryContentTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (currentDateDiary == null)
                  Text(
                    S.current.NoDiaryNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  )
                else
                // if (diary.content.footprintJpeg == null ||
                //     diary.content.footprintJpeg!.isEmpty)
                //   Text(
                //       'Footprint image not available, try set app location permission to always allow to enable this feature',
                //       style: TextStyle(color: const Color.fromARGB(255, 189, 0, 157)))
                // else
                //   Image.memory(
                //     base64Decode(diary.content.footprintJpeg!),
                //   ),
                // SizedBox(height: 16),
                  Text(
                    utf8.decode(currentDateDiary!.content.content.codeUnits),
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
