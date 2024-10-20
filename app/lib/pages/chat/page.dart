import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:foxxy_package/backend/http/api/messages.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/backend/schema/message.dart';
import 'package:foxxy_package/backend/schema/plugin.dart';
import 'package:foxxy_package/pages/chat/widgets/ai_message.dart';
import 'package:foxxy_package/pages/chat/widgets/animated_mini_banner.dart';
import 'package:foxxy_package/pages/chat/widgets/user_message.dart';
import 'package:foxxy_package/providers/connectivity_provider.dart';
import 'package:foxxy_package/providers/home_provider.dart';
import 'package:foxxy_package/providers/memory_provider.dart';
import 'package:foxxy_package/providers/message_provider.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
  });

  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with AutomaticKeepAliveClientMixin {
  TextEditingController textController = TextEditingController();
  late ScrollController scrollController;

  bool _showDeleteOption = false;
  bool isScrollingDown = false;

  var prefs = SharedPreferencesUtil();
  late List<Plugin> plugins;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool loading = false;

  changeLoadingState() {
    setState(() {
      loading = !loading;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    plugins = prefs.pluginsList;
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          _showDeleteOption = true;
          setState(() {});
          Future.delayed(const Duration(seconds: 5), () {
            if (isScrollingDown) {
              isScrollingDown = false;
              _showDeleteOption = false;
              setState(() {});
            }
          });
        }
      }

      if (scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          _showDeleteOption = false;
          setState(() {});
        }
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      scrollToBottom();
    });
    ;
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print('ChatPage build');
    return Consumer2<MessageProvider, ConnectivityProvider>(
      builder: (context, provider, connectivityProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: provider.isLoadingMessages
              ? AnimatedMiniBanner(
                  showAppBar: provider.isLoadingMessages,
                  child: Container(
                    width: double.infinity,
                    height: 10,
                    color: Colors.green,
                    child: const Center(
                      child: Text(
                        'Syncing messages with server...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                )
              : AnimatedMiniBanner(
                  showAppBar: _showDeleteOption,
                  height: 80,
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    color: Theme.of(context).primaryColor,
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        const Spacer(),
                        InkWell(
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                return getDialog(context, () {
                                  Navigator.of(context).pop();
                                }, () {
                                  setState(() {
                                    _showDeleteOption = false;
                                  });
                                  context.read<MessageProvider>().clearChat();
                                  Navigator.of(context).pop();
                                }, "Clear Chat?",
                                    "Are you sure you want to clear the chat? This action cannot be undone.");
                              },
                            );
                          },
                          child: const Text(
                            "Clear Chat  \u{1F5D1}",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: provider.isLoadingMessages && !provider.hasCachedMessages
                    ? Column(
                        children: [
                          const SizedBox(height: 100),
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.firstTimeLoadingText,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : provider.isClearingChat
                        ? const Column(
                            children: [
                              SizedBox(height: 100),
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Deleting your messages from Foxxy's memory...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : (provider.messages.isEmpty)
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 32.0),
                                  child: Text(
                                      connectivityProvider.isConnected
                                          ? '${S.current.NoMessagesYet}\n${S.current.WhyDontConversation}'
                                          : S.current
                                              .PleaseCheckInternetConnectionNote,
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                reverse: true,
                                controller: scrollController,
                                //  physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.messages.length,
                                itemBuilder: (context, chatIndex) {
                                  final message = provider.messages[chatIndex];
                                  double topPadding =
                                      chatIndex == provider.messages.length - 1
                                          ? 24
                                          : 16;
                                  double bottomPadding = chatIndex == 0
                                      ? Platform.isAndroid
                                          ? 200
                                          : 170
                                      : 0;
                                  return Padding(
                                    key: ValueKey(message.id),
                                    padding: EdgeInsets.only(
                                        bottom: bottomPadding,
                                        left: 18,
                                        right: 18,
                                        top: topPadding),
                                    child: message.sender == MessageSender.ai
                                        ? AIMessage(
                                            showTypingIndicator:
                                                provider.showTypingIndicator &&
                                                    chatIndex == 0,
                                            message: message,
                                            sendMessage: _sendMessageUtil,
                                            displayOptions:
                                                provider.messages.length <= 1,
                                            pluginSender:
                                                plugins.firstWhereOrNull((e) =>
                                                    e.id == message.pluginId),
                                            updateMemory:
                                                (ServerMemory memory) {
                                              context
                                                  .read<MemoryProvider>()
                                                  .updateMemory(memory);
                                            },
                                          )
                                        : HumanMessage(message: message),
                                  );
                                },
                              ),
              ),
              Consumer<HomeProvider>(builder: (context, home, child) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.maxFinite,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    margin: EdgeInsets.only(
                        left: 32,
                        right: 32,
                        bottom: home.isChatFieldFocused ? 120 : 120),
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
                    child: TextField(
                      enabled: true,
                      controller: textController,
                      // textCapitalization: TextCapitalization.sentences,
                      obscureText: false,
                      focusNode: home.chatFieldFocusNode,
                      // canRequestFocus: true,
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: S.current.AskYourAudioFairyAnything,
                        hintStyle:
                            const TextStyle(fontSize: 14.0, color: Colors.grey),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        suffixIcon: IconButton(
                          splashColor: Colors.transparent,
                          splashRadius: 1,
                          onPressed: loading
                              ? null
                              : () async {
                                  String message = textController.text;
                                  if (message.isEmpty) return;
                                  if (connectivityProvider.isConnected) {
                                    _sendMessageUtil(message);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(S.current
                                            .PleaseCheckInternetConnectionNote),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Color(0xFFF7F4F4),
                                  size: 24.0,
                                ),
                        ),
                      ),
                      // maxLines: 8,
                      // minLines: 1,
                      // keyboardType: TextInputType.multiline,
                      style: TextStyle(
                          fontSize: 14.0, color: Colors.grey.shade200),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  _sendMessageUtil(String message) async {
    changeLoadingState();
    String? pluginId =
        SharedPreferencesUtil().selectedChatPluginId == 'no_selected'
            ? null
            : SharedPreferencesUtil().selectedChatPluginId;
    var newMessage = ServerMessage(const Uuid().v4(), DateTime.now(), message,
        MessageSender.human, MessageType.text, pluginId, false, []);
    context.read<MessageProvider>().addMessage(newMessage);
    scrollToBottom();
    textController.clear();
    await context
        .read<MessageProvider>()
        .sendMessageToServer(message, pluginId);
    // TODO: restore streaming capabilities, with initial empty message
    scrollToBottom();
    changeLoadingState();
  }

  sendInitialPluginMessage(Plugin? plugin) async {
    changeLoadingState();
    scrollToBottom();
    ServerMessage message = await getInitialPluginMessage(plugin?.id);
    if (mounted) {
      context.read<MessageProvider>().addMessage(message);
    }
    scrollToBottom();
    changeLoadingState();
  }

  void _moveListToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  scrollToBottom() => _moveListToBottom();
}
