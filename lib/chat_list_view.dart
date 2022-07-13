import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_group_chat_demo/chat_list_view_controller.dart';

typedef OnAddChatItemHandler<T> = void Function(T item);
typedef OnClearHandler = void Function();
typedef OnJumpToBottom = void Function();
typedef ChatItemComparator<T> = bool Function(T a, T b);
typedef ChatMessageWidgetBuilder<T> = Widget Function(T item);

class ChatListView<T> extends StatefulWidget {
  final ChatListController<T> chatListController;
  final ChatMessageWidgetBuilder<T> itemBuilder;

  const ChatListView({
    Key? key,
    required this.chatListController,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  State<ChatListView> createState() => _ChatListViewState<T>();
}

class _ChatListViewState<T> extends State<ChatListView<T>> {
  final ScrollController _listViewScrollController = ScrollController();
  final ScrollController _singleChildScrollController = ScrollController();
  late ScrollController _activeScrollController;
  Drag? _drag;

  final List<T> chatList = [];
  final List<T> backLogChatList = [];

  bool get hovering =>
      (_listViewScrollController.hasClients && _listViewScrollController.offset > 0) ||
      (_singleChildScrollController.hasClients && _singleChildScrollController.position.extentAfter > 0);

  @override
  void initState() {
    widget.chatListController.setupHandlers(
      handleAddChatItem: (item) {
        var existedIndex = backLogChatList.indexWhere(
          (element) => widget.chatListController.chatItemComparator(element, item),
        );
        if (existedIndex > -1) {
          return setState(() {
            backLogChatList[existedIndex] = item;
          });
        }
        existedIndex = chatList.indexWhere((element) => widget.chatListController.chatItemComparator(element, item));
        if (existedIndex > -1) {
          return setState(() {
            chatList[existedIndex] = item;
          });
        }
        setState(() {
          if (hovering) {
            backLogChatList.add(item);
          } else {
            chatList.insert(0, item);
          }
        });
      },
      handleClear: () {
        setState(() {
          chatList.clear();
          backLogChatList.clear();
        });
      },
      handleJumpToBottom: () {
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
                              itemBuilder: (context, index) => widget.itemBuilder(chatList[index]),
                            ),
                          ),
                          Container(
                            color: Colors.yellow,
                            child: Column(
                              children: backLogChatList.map(widget.itemBuilder).toList(),
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

  final _voidCallback = () {};

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
          _voidCallback);
    }
    _drag?.update(details);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_singleChildScrollController.offset > 0) {
      _activeScrollController = _singleChildScrollController;
    } else {
      _activeScrollController = _listViewScrollController;
    }
    _drag = _activeScrollController.position.drag(details, _voidCallback);
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
