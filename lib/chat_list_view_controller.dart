import 'package:flutter_group_chat_demo/chat_list_view.dart';

class ChatListController<T> {
  late OnAddChatItemHandler<T> _onAddChatItemHandler;
  late OnClearHandler _onClearHandler;
  late OnJumpToBottom _onJumpToBottom;
  final ChatItemComparator<T> chatItemComparator;

  ChatListController({
    required this.chatItemComparator,
  });

  void addChatItem(T item) => _onAddChatItemHandler.call(item);

  void clear() => _onClearHandler.call();

  void setupHandlers({
    required OnAddChatItemHandler<T> handleAddChatItem,
    required OnClearHandler handleClear,
    required OnJumpToBottom handleJumpToBottom,
  }) {
    this._onAddChatItemHandler = handleAddChatItem;
    this._onClearHandler = handleClear;
    this._onJumpToBottom = handleJumpToBottom;
  }

  void jumpToBottom() {
    _onJumpToBottom.call();
  }
}
