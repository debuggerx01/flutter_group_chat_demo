import 'package:chat_bubbles/bubbles/bubble_special_one.dart';
import 'package:flutter/material.dart';
import 'package:flutter_group_chat_demo/chat_list_view.dart';
import 'dart:math';
import 'package:dart_mock/dart_mock.dart' as mock;
import 'package:flutter_group_chat_demo/chat_list_view_controller.dart';

int counter = 0;
int historyCount = 3;

@immutable
class MessageItem {
  final bool isSelf;
  final String content;
  final DateTime timeStamp;

  const MessageItem({
    required this.isSelf,
    required this.content,
    required this.timeStamp,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final MessageListController<MessageItem> _messageListController = MessageListController<MessageItem>(
    messageItemComparator: (a, b) => a.timeStamp == b.timeStamp,
    onFetchHistoryMessage: ([lastMessageItem]) {
      var t = (lastMessageItem?.timeStamp ?? DateTime.now()).millisecondsSinceEpoch;
      if (--historyCount < 0) return null;
      return List.generate(
        10,
        (index) => MessageItem(
            isSelf: index.isEven,
            content: '${10 - index} : ${mock.string(min: 20, max: 100)}',
            timeStamp: DateTime.fromMillisecondsSinceEpoch(t - index - 1)),
      );
    },
  );

  @override
  void initState() {
    super.initState();
    _messageListController.isHovering.listen((event) {
      print('isHovering: $event');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_downward_outlined),
            onPressed: _messageListController.jumpToBottom,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: _messageListController.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          ChatListView<MessageItem>(
            chatListController: _messageListController,
            itemBuilder: (item) => GestureDetector(
              onTap: () {
                _messageListController.addMessageItem(MessageItem(
                    isSelf: item.isSelf,
                    content: '${item.content.split(':').first}: DebuggerX',
                    timeStamp: item.timeStamp));
              },
              child: BubbleSpecialOne(
                text: item.content,
                color: item.isSelf ? const Color(0xFF1B97F3) : const Color(0xFFA3A3A4),
                textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                isSender: item.isSelf,
                key: Key(item.timeStamp.toIso8601String()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.multiline,
                    controller: _textEditingController,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    var content = _textEditingController.text.trim();
                    if (content.isNotEmpty) {
                      _messageListController.jumpToBottom();
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        _messageListController.addMessageItem(
                          (MessageItem(isSelf: true, content: content, timeStamp: DateTime.now())),
                        );
                        _mockGroupMessage();
                      });
                    }
                    _textEditingController.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mockGroupMessage() {
    var random = Random(DateTime.now().millisecondsSinceEpoch);
    var count = random.nextInt(20) + 10;
    Future.doWhile(() async {
      count--;
      if (count < 0) return false;
      await Future.delayed(
        Duration(milliseconds: random.nextInt(1000) + 100),
        () => _messageListController.addMessageItem(
          MessageItem(
              isSelf: false, content: '${++counter} : ${mock.string(min: 20, max: 100)}', timeStamp: DateTime.now()),
        ),
      );
      return true;
    });
  }
}
