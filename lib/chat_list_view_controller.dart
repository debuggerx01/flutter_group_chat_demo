import 'dart:async';

import 'package:flutter_group_chat_demo/chat_list_view.dart';

class MessageListController<T> {
  late OnAddMessageItemHandler<T> _onAddMessageItemHandler;
  late OnClearHandler _onClearHandler;
  late OnJumpToBottom _onJumpToBottom;
  final MessageItemComparator<T> messageItemComparator;
  late StreamController<bool> _isHoveringController;
  late Stream<bool> _isHovering;

  MessageListController({
    required this.messageItemComparator,
  }) {
    _isHoveringController = StreamController()..add(false);
    _isHovering = _isHoveringController.stream.asBroadcastStream();
  }

  void updateHoveringStatus(bool hovering) {
    _isHoveringController.add(hovering);
  }

  void addMessageItem(T item) => _onAddMessageItemHandler.call(item);

  void clear() => _onClearHandler.call();

  Stream<bool> get isHovering => _isHovering;

  void setupHandlers({
    required OnAddMessageItemHandler<T> handleAddMessageItem,
    required OnClearHandler handleClear,
    required OnJumpToBottom handleJumpToBottom,
  }) {
    this._onAddMessageItemHandler = handleAddMessageItem;
    this._onClearHandler = handleClear;
    this._onJumpToBottom = handleJumpToBottom;
  }

  void jumpToBottom() {
    _onJumpToBottom.call();
  }
}
