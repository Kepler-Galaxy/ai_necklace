import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:friend_private/generated/l10n.dart';
import 'package:friend_private/pages/diary/memory_chains_view.dart';

class DiaryTabView extends StatelessWidget {
  final List<MemoryConnectionNode> forest;
  final Widget diaryContent;

  const DiaryTabView({
    Key? key,
    required this.forest,
    required this.diaryContent,
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
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Tab(
                child: Text(
                  S.current.MemoryContents,
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: MemoryChainsView(forest: forest),
                  physics: const BouncingScrollPhysics(),
                ),
                SingleChildScrollView(
                  child: diaryContent,
                  physics: const BouncingScrollPhysics(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
