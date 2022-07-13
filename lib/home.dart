import 'package:flutter/material.dart';
import 'package:flutter_group_chat_demo/chat_list_view.dart';
import 'dart:math';
import 'package:dart_mock/dart_mock.dart' as mock;

int counter = 0;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ChatListController _chatListController = ChatListController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_downward_outlined),
            onPressed: _chatListController.jumpToBottom,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: _chatListController.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          ChatListView(
            chatListController: _chatListController,
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
                      _chatListController.jumpToBottom();
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        _chatListController.addChatItem(
                          (ChatItem(isSelf: true, content: content)),
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
        () => _chatListController.addChatItem(
          ChatItem(isSelf: false, content: '${++counter} : ${mock.string(min: 20, max: 100)}'),
        ),
      );
      return true;
    });
  }
}
