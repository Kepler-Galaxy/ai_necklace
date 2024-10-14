import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/pages/capture/widgets/widgets.dart';
import 'package:foxxy_package/pages/memories/widgets/date_list_item.dart';
import 'package:foxxy_package/pages/memories/widgets/processing_capture.dart';
import 'package:foxxy_package/providers/memory_provider.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:foxxy_package/widgets/web_link_input.dart';
import 'package:foxxy_package/generated/l10n.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'widgets/empty_memories.dart';
import 'widgets/memory_list_item.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/pages/settings/widgets.dart';
import 'package:foxxy_package/widgets/dialog.dart';

class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key});

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage>
    with AutomaticKeepAliveClientMixin {
  late String _selectedLanguage;
  TextEditingController textController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _selectedLanguage = SharedPreferencesUtil().recordingsLanguage;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Provider.of<MemoryProvider>(context, listen: false)
          .memories
          .isEmpty) {
        await Provider.of<MemoryProvider>(context, listen: false)
            .getInitialMemories();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building memories page');
    super.build(context);
    return Consumer<MemoryProvider>(builder: (context, memoryProvider, child) {
      return RefreshIndicator(
        backgroundColor: Colors.black,
        color: Colors.white,
        onRefresh: () async {
          return await memoryProvider.getInitialMemories();
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // const SliverToBoxAdapter(child: SpeechProfileCardWidget()),
            SliverToBoxAdapter(child: getMemoryCaptureWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: memoryProvider.isCreatingWeChatMemory
                          ? null
                          : () {
                              _showWebLinkArticleInput(context);
                            },
                      child: Row(children: [
                        Text(
                          memoryProvider.isCreatingWeChatMemory
                              ? S.current.CreatingMemory
                              : S.current.ImportArticle,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        memoryProvider.isCreatingWeChatMemory
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                      ]),
                    ),
                    GestureDetector(
                      onTap: memoryProvider.toggleDiscardMemories,
                      child: Row(
                        children: [
                          Text(
                            SharedPreferencesUtil().showDiscardedMemories
                                ? S.current.HideDiscarded
                                : S.current.ShowDiscarded,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            SharedPreferencesUtil().showDiscardedMemories
                                ? Icons.filter_list_off_sharp
                                : Icons.filter_list,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (memoryProvider.memoriesWithDates.isEmpty &&
                !memoryProvider.isLoadingMemories)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: EmptyMemoriesWidget(),
                  ),
                ),
              )
            else if (memoryProvider.memoriesWithDates.isEmpty &&
                memoryProvider.isLoadingMemories)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == memoryProvider.memoriesWithDates.length) {
                      if (memoryProvider.isLoadingMemories) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 32.0),
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        );
                      }
                      // widget.loadMoreMemories(); // CALL this only when visible
                      return VisibilityDetector(
                        key: const Key('memory-loader'),
                        onVisibilityChanged: (visibilityInfo) {
                          if (visibilityInfo.visibleFraction > 0 &&
                              !memoryProvider.isLoadingMemories) {
                            memoryProvider.getMoreMemoriesFromServer();
                          }
                        },
                        child:
                            const SizedBox(height: 80, width: double.maxFinite),
                      );
                    }

                    if (memoryProvider.memoriesWithDates[index].runtimeType ==
                        DateTime) {
                      return DateListItem(
                          date: memoryProvider.memoriesWithDates[index]
                              as DateTime,
                          isFirst: index == 0);
                    }
                    var memory =
                        memoryProvider.memoriesWithDates[index] as ServerMemory;
                    return MemoryListItem(
                      memoryIdx:
                          memoryProvider.memoriesWithDates.indexOf(memory),
                      memory: memory,
                    );
                  },
                  childCount: memoryProvider.memoriesWithDates.length + 1,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      );
    });
  }
}

void _showWebLinkArticleInput(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return WebLinkArticleInputWidget();
    },
  );
}
