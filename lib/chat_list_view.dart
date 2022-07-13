import 'package:chat_bubbles/bubbles/bubble_special_one.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef OnAddChatItemHandler = void Function(ChatItem);
typedef OnClearHandler = void Function();
typedef OnJumpToBottom = void Function();

@immutable
class ChatItem {
  final bool isSelf;
  final String content;

  const ChatItem({
    required this.isSelf,
    required this.content,
  });
}

class ChatListController {
  OnAddChatItemHandler? onAddChatItemHandler;
  OnClearHandler? onClearHandler;
  OnJumpToBottom? onJumpToBottom;

  void addChatItem(ChatItem item) => onAddChatItemHandler?.call(item);

  void clear() => onClearHandler?.call();

  void setHandlers({
    required OnAddChatItemHandler onAddChatItemHandler,
    required OnClearHandler onClearHandler,
    required OnJumpToBottom onJumpToBottom,
  }) {
    this.onAddChatItemHandler = onAddChatItemHandler;
    this.onClearHandler = onClearHandler;
    this.onJumpToBottom = onJumpToBottom;
  }

  void jumpToBottom() {
    onJumpToBottom?.call();
  }
}

class ChatListView extends StatefulWidget {
  final ChatListController chatListController;

  const ChatListView({
    Key? key,
    required this.chatListController,
  }) : super(key: key);

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final ScrollController _listViewScrollController = ScrollController();
  final ScrollController _singleChildScrollController = ScrollController();
  late ScrollController _activeScrollController;
  Drag? _drag;

  List<ChatItem> chatList = [];
  List<ChatItem> backLogChatList = [];

  bool get hovering =>
      (_listViewScrollController.hasClients && _listViewScrollController.offset > 0) ||
      (_singleChildScrollController.hasClients && _singleChildScrollController.position.extentAfter > 0);

  @override
  void initState() {
    widget.chatListController.setHandlers(
      onAddChatItemHandler: (item) {
        setState(() {
          if (hovering) {
            backLogChatList.add(item);
          } else {
            chatList.insert(0, item);
          }
        });
      },
      onClearHandler: () {
        setState(() {
          chatList.clear();
          backLogChatList.clear();
        });
      },
      onJumpToBottom: () {
        if (_listViewScrollController.hasClients) {
          _listViewScrollController.jumpTo(0);
        }
        handleClearBackLogList();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox.expand(
        child: chatList.isEmpty
            ? Container()
            : LayoutBuilder(builder: (context, constrains) {
                return RawGestureDetector(
                  gestures: {
                    VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                      (instance) => instance
                        ..onStart = _handleDragStart
                        ..onUpdate = _handleDragUpdate
                        ..onEnd = _handleDragEnd
                        ..onCancel = _handleDragCancel,
                    ),
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification && notification.metrics.extentAfter == 0.0) {
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          handleClearBackLogList();
                        });
                      }
                      return true;
                    },
                    child: SingleChildScrollView(
                      controller: _singleChildScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: constrains.maxHeight),
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: _listViewScrollController,
                              itemCount: chatList.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                var chatItem = chatList[index];
                                return BubbleSpecialOne(
                                  text: chatItem.content,
                                  color: chatItem.isSelf ? const Color(0xFF1B97F3) : const Color(0xFFA3A3A4),
                                  textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                                  isSender: chatItem.isSelf,
                                );
                              },
                            ),
                          ),
                          Container(
                            color: Colors.yellow,
                            child: Column(
                              children: backLogChatList
                                  .map((chatItem) => BubbleSpecialOne(
                                        text: chatItem.content,
                                        color: chatItem.isSelf ? const Color(0xFF1B97F3) : const Color(0xFFA3A3A4),
                                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                                        isSender: chatItem.isSelf,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    late ScrollController _preferScrollController;
    if (details.delta.dy > 0) {
      /// up
      if (_singleChildScrollController.offset > 0) {
        _preferScrollController = _singleChildScrollController;
      } else {
        _preferScrollController = _listViewScrollController;
      }
    } else {
      /// down
      if (_listViewScrollController.offset > 0) {
        _preferScrollController = _listViewScrollController;
      } else {
        _preferScrollController = _singleChildScrollController;
      }
    }
    if (_preferScrollController != _activeScrollController) {
      _drag?.cancel();
      _activeScrollController = _preferScrollController;
      _drag = _activeScrollController.position.drag(
          DragStartDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
          ),
          () {});
    }
    _drag?.update(details);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_singleChildScrollController.offset > 0) {
      _activeScrollController = _singleChildScrollController;
    } else {
      _activeScrollController = _listViewScrollController;
    }
    _drag = _activeScrollController.position.drag(details, () {});
  }

  void _handleDragEnd(DragEndDetails details) {
    _drag?.end(details);
  }

  void _handleDragCancel() {
    _drag?.cancel();
  }

  handleClearBackLogList() {
    setState(() {
      if (_singleChildScrollController.hasClients) {
        _singleChildScrollController.position.jumpTo(0);
      }
      chatList.insertAll(0, backLogChatList.reversed);
      backLogChatList.clear();
    });
  }
}
