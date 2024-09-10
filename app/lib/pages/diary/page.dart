import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/diary.dart';
import 'package:friend_private/pages/diary/widgets/date_list_item.dart';
import 'package:friend_private/pages/diary/widgets/diary_list_item.dart';
import 'package:friend_private/pages/diary/widgets/empty_diaries.dart';
import 'package:friend_private/providers/diary_provider.dart';
import 'package:friend_private/providers/home_provider.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({
    super.key,
  });

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with AutomaticKeepAliveClientMixin {
  TextEditingController textController = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Provider.of<DiaryProvider>(context, listen: false).diaries.isEmpty) {
        await Provider.of<DiaryProvider>(context, listen: false).getInitialDiaries();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building diary page');
    super.build(context);
    return Consumer<DiaryProvider>(builder: (context, diaryProvider, child) {
      bool isEmpty = diaryProvider.diaries.isEmpty && !diaryProvider.isLoadingDiaries;
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: isEmpty ? 8 : 32)),
          SliverToBoxAdapter(
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay, _) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                diaryProvider.selectDiary(selectedDay);
              },
              eventLoader: (day) {
                return diaryProvider.getDiariesForDay(day);
              },
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32)),
          isEmpty
              ? const SliverToBoxAdapter(child: SizedBox())
              : SliverToBoxAdapter(
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      border: GradientBoxBorder(
                        gradient: LinearGradient(colors: [
                          Color.fromARGB(127, 208, 208, 208),
                          Color.fromARGB(127, 188, 99, 121),
                          Color.fromARGB(127, 86, 101, 182),
                          Color.fromARGB(127, 126, 190, 236)
                        ]),
                        width: 1,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    child: Consumer<HomeProvider>(builder: (context, home, child) {
                      return TextField(
                        enabled: true,
                        controller: textController,
                        onChanged: (s) {
                          diaryProvider.filterDiaries(s);
                        },
                        obscureText: false,
                        autofocus: false,
                        focusNode: home.diaryFieldFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search for diaries...',
                          hintStyle: const TextStyle(fontSize: 14.0, color: Colors.grey),
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          suffixIcon: textController.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Color(0xFFF7F4F4),
                                    size: 28.0,
                                  ),
                                  onPressed: () {
                                    textController.clear();
                                    diaryProvider.initFilteredDiaries();
                                  },
                                ),
                        ),
                        style: TextStyle(fontSize: 14.0, color: Colors.grey.shade200),
                      );
                    }),
                  ),
                ),
          if (diaryProvider.diariesWithDates.isEmpty && !diaryProvider.isLoadingDiaries)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 32.0),
                  child: EmptyDiariesWidget(),
                ),
              ),
            )
          else if (diaryProvider.diariesWithDates.isEmpty && diaryProvider.isLoadingDiaries)
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
                  if (index == diaryProvider.diariesWithDates.length) {
                    if (diaryProvider.isLoadingDiaries) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 32.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      );
                    }
                    return VisibilityDetector(
                      key: const Key('diary-loader'),
                      onVisibilityChanged: (visibilityInfo) {
                        if (visibilityInfo.visibleFraction > 0 && !diaryProvider.isLoadingDiaries) {
                          diaryProvider.getMoreDiariesFromServer();
                        }
                      },
                      child: const SizedBox(height: 80, width: double.maxFinite),
                    );
                  }

                  if (diaryProvider.diariesWithDates[index].runtimeType == DateTime) {
                    return DateListItem(date: diaryProvider.diariesWithDates[index] as DateTime, isFirst: index == 0);
                  }
                  var diary = diaryProvider.diariesWithDates[index] as ServerDiary;
                  return DiaryListItem(
                    diaryIdx: diaryProvider.diariesWithDates.indexOf(diary),
                    diary: diary,
                    updateDiary: diaryProvider.updateDiary,
                    deleteDiary: diaryProvider.deleteDiary,
                  );
                },
                childCount: diaryProvider.diariesWithDates.length + 1,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      );
    });
  }
}