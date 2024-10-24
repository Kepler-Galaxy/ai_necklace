import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_provider_utilities/flutter_provider_utilities.dart';
import 'package:foxxy_package/backend/http/api/memories.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/backend/schema/person.dart';
import 'package:foxxy_package/pages/home/page.dart';
import 'package:foxxy_package/pages/memory_detail/widgets.dart';
import 'package:foxxy_package/pages/settings/people.dart';
import 'package:foxxy_package/pages/settings/recordings_storage_permission.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/utils/other/temp.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:foxxy_package/widgets/expandable_text.dart';
import 'package:foxxy_package/widgets/extensions/string.dart';
import 'package:foxxy_package/widgets/photos_grid.dart';
import 'package:foxxy_package/widgets/transcript.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

import 'memory_detail_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MemoryDetailPage extends StatefulWidget {
  final ServerMemory memory;
  final bool isFromOnboarding;
  final bool isPopup;

  const MemoryDetailPage({
    Key? key,
    required this.memory,
    this.isFromOnboarding = false,
    this.isPopup = false,
  }) : super(key: key);

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final focusTitleField = FocusNode();
  final focusOverviewField = FocusNode();

  // TODO: use later for onboarding transcript segment edits
  // late AnimationController _animationController;
  // late Animation<double> _opacityAnimation;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var provider = Provider.of<MemoryDetailProvider>(context, listen: false);
      await provider.initMemory();
    });
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 60),
    // )..repeat(reverse: true);
    //
    // _opacityAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(_animationController);

    super.initState();
  }

  @override
  void dispose() {
    focusTitleField.dispose();
    focusOverviewField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isPopup,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: MessageListener<MemoryDetailProvider>(
          showError: (error) {
            if (error == 'REPROCESS_FAILED') {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Error while processing memory. Please try again later.')));
            }
          },
          showInfo: (info) {
            if (info == 'REPROCESS_SUCCESS') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Memory processed! 🚀',
                        style: TextStyle(color: Colors.white))),
              );
            }
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Theme.of(context).colorScheme.primary,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Consumer<MemoryDetailProvider>(
                  builder: (context, provider, child) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (widget.isFromOnboarding) {
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HomePageWrapper()),
                                (route) => false);
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 24.0),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text("${provider.structured.getEmoji()}")),
                    IconButton(
                      onPressed: () async {
                        if (provider.memory.failed) {
                          showDialog(
                            context: context,
                            builder: (c) => getDialog(
                              context,
                              () => Navigator.pop(context),
                              () => Navigator.pop(context),
                              'Options not available',
                              'This memory failed when processing. Options are not available yet, please try again later.',
                              singleButton: true,
                              okButtonText: S.current.Ok,
                            ),
                          );
                          return;
                        } else {
                          await showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            builder: (context) {
                              return const ShowOptionsBottomSheet();
                            },
                          ).whenComplete(() {
                            provider.toggleShareOptionsInSheet(false);
                            provider.toggleDevToolsInSheet(false);
                          });
                        }
                      },
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                );
              }),
            ),
            floatingActionButton: Selector<MemoryDetailProvider, int>(
                selector: (context, provider) => provider.selectedTab,
                builder: (context, selectedTab, child) {
                  return selectedTab == 0
                      ? FloatingActionButton(
                          backgroundColor: Colors.black,
                          elevation: 8,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32)),
                              side: BorderSide(color: Colors.grey, width: 1)),
                          onPressed: () {
                            var provider = Provider.of<MemoryDetailProvider>(
                                context,
                                listen: false);
                            Clipboard.setData(ClipboardData(
                                text: provider.memory
                                    .getTranscript(generate: true)));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Transcript copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ));
                            MixpanelManager().copiedMemoryDetails(
                                provider.memory,
                                source: 'Transcript');
                          },
                          child: const Icon(Icons.copy_rounded,
                              color: Colors.white, size: 20),
                        )
                      : const SizedBox.shrink();
                }),
            body: Column(
              children: [
                TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: false,
                  onTap: (value) {
                    context
                        .read<MemoryDetailProvider>()
                        .updateSelectedTab(value);
                  },
                  padding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  labelStyle: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 18),
                  tabs: [
                    Selector<MemoryDetailProvider, ServerMemory>(
                        selector: (context, provider) => provider.memory,
                        builder: (context, memory, child) {
                          return Tab(
                            text: _getTabText(memory),
                          );
                        }),
                    Tab(text: S.current.Summary)
                  ],
                  indicator: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Builder(builder: (context) {
                      return TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Selector<MemoryDetailProvider, ServerMemory>(
                            selector: (context, provider) => provider.memory,
                            builder: (context, memory, child) {
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  if (memory.source == MemorySource.openglass) ...[
                                    const PhotosGridComponent(),
                                    const SizedBox(height: 32),
                                  ]
                                  else if (memory.source == MemorySource.web_link) ...[
                                    if (memory.externalLink?.webContentResponse?.response is LittleRedBookContentResponse) 
                                      const LittleRedBookWidget()
                                    else 
                                      const WebContentWidgets(),
                                  ]
                                  else ...[
                                    const TranscriptWidgets(),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SummaryTab(),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTabText(ServerMemory memory) {
    if (memory.source == MemorySource.openglass) {
      return 'Photos';
    } else if (memory.source == MemorySource.screenpipe) {
      return 'Raw Data';
    } else if (memory.source == MemorySource.web_link) {
      if (memory.externalLink?.webContentResponse?.response is LittleRedBookContentResponse) {
        return S.current.LittleRedBook;
      } else if (memory.externalLink?.webContentResponse?.response is WeChatContentResponse) {
        return S.current.WeChat;
      } else if (memory.externalLink?.webContentResponse?.response is GeneralWebContentResponse) {
        return S.current.GeneralWebContent;
      } else {
        return S.current.GeneralWebContent;
      }
    } else {
      return S.current.Transcript;
    }
  }
}

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MemoryDetailProvider, bool>(
      selector: (context, provider) => provider.memory.discarded,
      builder: (context, isDiscaarded, child) {
        return ListView(
          shrinkWrap: true,
          children: [
            const GetSummaryWidgets(),
            // isDiscaarded ? const ReprocessDiscardedWidget() : const GetPluginsWidgets(),
            if (isDiscaarded) const ReprocessDiscardedWidget(),
            const GetGeolocationWidgets(),
          ],
        );
      },
    );
  }
}

class TranscriptWidgets extends StatelessWidget {
  const TranscriptWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryDetailProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            SizedBox(
                height: provider.memory.transcriptSegments.isEmpty ? 16 : 0),
            // provider.memory.isPostprocessing()
            //     ? Container(
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: Colors.grey.shade800,
            //           borderRadius: BorderRadius.circular(8),
            //         ),
            //         child: Text('🚨 Memory still processing. Please wait before reassigning segments.',
            //             style: TextStyle(color: Colors.grey.shade300, fontSize: 15, height: 1.3)),
            //       )
            //     : const SizedBox(height: 0),
            SizedBox(
                height: provider.memory.transcriptSegments.isEmpty ? 16 : 0),
            provider.memory.transcriptSegments.isEmpty
                ? ExpandableTextWidget(
                    text: (provider.memory.externalIntegration?.text ?? '')
                        .decodeSting,
                    maxLines: 10000,
                    linkColor: Colors.grey.shade300,
                    style: TextStyle(
                        color: Colors.grey.shade300, fontSize: 15, height: 1.3),
                    toggleExpand: () {
                      provider.toggleIsTranscriptExpanded();
                    },
                    isExpanded: provider.isTranscriptExpanded,
                  )
                : TranscriptWidget(
                    segments: provider.memory.transcriptSegments,
                    horizontalMargin: false,
                    topMargin: false,
                    canDisplaySeconds: provider.canDisplaySeconds,
                    isMemoryDetail: true,
                    editSegment: (_) {},
                    // editSegment: !provider.memory.isPostprocessing()
                    //     ? (i) {
                    //         final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
                    //         if (!connectivityProvider.isConnected) {
                    //           ConnectivityProvider.showNoInternetDialog(context);
                    //           return;
                    //         }
                    //         showModalBottomSheet(
                    //           context: context,
                    //           isScrollControlled: true,
                    //           isDismissible: provider.editSegmentLoading ? false : true,
                    //           shape: const RoundedRectangleBorder(
                    //             borderRadius:
                    //                 BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    //           ),
                    //           builder: (context) {
                    //             return EditSegmentWidget(
                    //               segmentIdx: i,
                    //               people: SharedPreferencesUtil().cachedPeople,
                    //             );
                    //           },
                    //         );
                    //       }
                    //     : (_) {
                    //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    //           content: Text('Memory still processing. Please wait...'),
                    //           duration: Duration(seconds: 1),
                    //         ));
                    //       },
                  ),
            const SizedBox(height: 32)
          ],
        );
      },
    );
  }
}

class WebContentWidgets extends StatelessWidget {
  const WebContentWidgets({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryDetailProvider>(
      builder: (context, provider, child) {
        final webContentResponse = provider.memory.externalLink?.webContentResponse;
        final String webContent = webContentResponse?.response.mainContent ?? 'No content available';
        final String title = webContentResponse?.response.title ?? 'No title available';
        final String url = webContentResponse?.response.url ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 8),
            if (url.isNotEmpty)
              InkWell(
                onTap: () async {
                  final Uri uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch $url')),
                    );
                  }
                },
                child: Text(
                  url,
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ExpandableTextWidget(
              text: webContent,
              maxLines: 10000,
              linkColor: Colors.grey.shade300,
              style: TextStyle(
                  color: Colors.grey.shade300, fontSize: 15, height: 1.3),
              isExpanded: provider.isTranscriptExpanded,
              toggleExpand: () => provider.toggleIsTranscriptExpanded(),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class EditSegmentWidget extends StatelessWidget {
  final int segmentIdx;
  final List<Person> people;

  const EditSegmentWidget(
      {super.key, required this.segmentIdx, required this.people});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryDetailProvider>(builder: (context, provider, child) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        height: 320,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text('Who\'s segment is this?',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            MixpanelManager().unassignedSegment();
                            provider.unassignMemoryTranscriptSegment(
                                provider.memory.id, segmentIdx);
                            // setModalState(() {
                            //   personId = null;
                            //   isUserSegment = false;
                            // });
                            // setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Un-assign',
                            style: TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  !provider.hasAudioRecording
                      ? const SizedBox(height: 12)
                      : const SizedBox(),
                  !provider.hasAudioRecording
                      ? GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (c) => getDialog(
                                context,
                                () => Navigator.pop(context),
                                () {
                                  Navigator.pop(context);
                                  routeToPage(context,
                                      const RecordingsStoragePermission());
                                },
                                'Can\'t be used for speech training',
                                'This segment can\'t be used for speech training as there is no audio recording available. Check if you have the required permissions for future memories.',
                                okButtonText: 'View',
                              ),
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Can\'t be used for speech training',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                            decoration:
                                                TextDecoration.underline)),
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.info,
                                      color: Colors.grey, size: 20),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Yours'),
                    value:
                        provider.memory.transcriptSegments[segmentIdx].isUser,
                    checkboxShape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    onChanged: (bool? value) async {
                      if (provider.editSegmentLoading) return;
                      // setModalState(() => loading = true);
                      provider.toggleEditSegmentLoading(true);
                      MixpanelManager().assignedSegment('User');
                      provider.memory.transcriptSegments[segmentIdx].isUser =
                          true;
                      provider.memory.transcriptSegments[segmentIdx].personId =
                          null;
                      bool result = await assignMemoryTranscriptSegment(
                        provider.memory.id,
                        segmentIdx,
                        isUser: true,
                        useForSpeechTraining:
                            SharedPreferencesUtil().hasSpeakerProfile,
                      );
                      try {
                        provider.toggleEditSegmentLoading(false);
                        Navigator.pop(context);
                        if (SharedPreferencesUtil().hasSpeakerProfile) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result
                                  ? 'Segment assigned, and speech profile updated!'
                                  : 'Segment assigned, but speech profile failed to update. Please try again later.'),
                            ),
                          );
                        }
                      } catch (e) {}
                    },
                  ),
                  for (var person in people)
                    CheckboxListTile(
                      title: Text('${person.name}\'s'),
                      value: provider
                              .memory.transcriptSegments[segmentIdx].personId ==
                          person.id,
                      checkboxShape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      onChanged: (bool? value) async {
                        if (provider.editSegmentLoading) return;
                        provider.toggleEditSegmentLoading(true);
                        MixpanelManager().assignedSegment('User Person');
                        provider.memory.transcriptSegments[segmentIdx].isUser =
                            false;
                        provider.memory.transcriptSegments[segmentIdx]
                            .personId = person.id;
                        bool result = await assignMemoryTranscriptSegment(
                            provider.memory.id, segmentIdx,
                            personId: person.id);
                        // TODO: make this un-closable or in a way that they receive the result
                        try {
                          provider.toggleEditSegmentLoading(false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result
                                  ? 'Segment assigned, and ${person.name}\'s speech profile updated!'
                                  : 'Segment assigned, but speech profile failed to update. Please try again later.'),
                            ),
                          );
                        } catch (e) {}
                      },
                    ),
                  ListTile(
                    title: const Text('Someone else\'s'),
                    trailing: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.add),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      routeToPage(context, const UserPeoplePage());
                    },
                  ),
                ],
              ),
            ),
            if (provider.editSegmentLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                    child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                )),
              ),
          ],
        ),
      );
    });
  }
}


class LittleRedBookWidget extends StatelessWidget {
  const LittleRedBookWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<MemoryDetailProvider, MemoryExternalLink?>(
      selector: (context, provider) => provider.memory.externalLink,
      builder: (context, memoryExternalLink, child) {
        if (memoryExternalLink?.webContentResponse?.response is! LittleRedBookContentResponse) {
          return const SizedBox.shrink();
        }

        final littleRedBookContent = memoryExternalLink!.webContentResponse!.response as LittleRedBookContentResponse;
        final imageDescriptions = memoryExternalLink.webPhotoUnderstanding ?? [];

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: littleRedBookContent.imageUrls.length,
          itemBuilder: (context, idx) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    idx < imageDescriptions.length ? imageDescriptions[idx].description : 'No description available',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageView(
                          imageUrl: littleRedBookContent.imageUrls[idx],
                          tag: 'image_$idx',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'image_$idx',
                    child: FutureBuilder<ImageInfo>(
                      future: _getImageInfo(littleRedBookContent.imageUrls[idx]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          final aspectRatio = snapshot.data!.image.width / snapshot.data!.image.height;
                          return AspectRatio(
                            aspectRatio: aspectRatio,
                            child: Image.network(
                              littleRedBookContent.imageUrls[idx],
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return const Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Future<ImageInfo> _getImageInfo(String imageUrl) async {
    final Completer<ImageInfo> completer = Completer();
    final ImageStream stream = NetworkImage(imageUrl).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    });
    stream.addListener(listener);
    final ImageInfo imageInfo = await completer.future;
    stream.removeListener(listener);
    return imageInfo;
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImageView({Key? key, required this.imageUrl, required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: tag,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}


