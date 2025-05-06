import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:chatbot_lini/services/api_service.dart';
import 'dart:io';

final _uuid = Uuid();

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  Chat({
    String? id,
    String? title,
    DateTime? createdAt,
    List<ChatMessage>? messages,
  })  : id = id ?? _uuid.v4(),
        title = title ?? 'New Chat',
        createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  Chat copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<ChatMessage>? messages,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String? imagePath;
  final bool isSearch;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.imagePath,
    this.isSearch = false,
    DateTime? timestamp,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Chat> _chats = [];
  String? _currentChatId;
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._apiService) {
    _loadChats();
  }

  List<Chat> get chats => _chats;
  String? get currentChatId => _currentChatId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Chat? get currentChat {
    if (_chats.isEmpty) return null;
    if (_currentChatId == null) {
      _currentChatId = _chats.first.id;
      return _chats.first;
    }
    return _chats.firstWhere(
      (chat) => chat.id == _currentChatId,
      orElse: () {
        _currentChatId = _chats.first.id;
        return _chats.first;
      },
    );
  }

  Future<void> _loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getChatHistory();
      if (response['status'] == 'success') {
        final history = response['data'] as List;
        _chats = history.map((chat) {
          final messages = (chat['history'] as List).map((msg) {
            return ChatMessage(
              text: msg['content'],
              isUser: msg['role'] == 'user',
              imagePath: null,
              isSearch: false,
            );
          }).toList();

          final chatId = chat['id'].toString();
          return Chat(
            id: chatId,
            title: 'Chat $chatId',
            createdAt: DateTime.parse(chat['created_at']),
            messages: messages,
          );
        }).toList();

        if (_chats.isNotEmpty) {
          _currentChatId = _chats.first.id;
        }

        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to load chat history: ${response['message']}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateChatWithResponse(Map<String, dynamic> response) {
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to process request');
    }

    final conversationId = response['conversation_id']?.toString();
    if (conversationId == null) {
      throw Exception('Invalid response format: missing conversation_id');
    }

    final history = response['history'] as List;
    if (history.isEmpty) {
      throw Exception('Invalid response format: empty history');
    }

    final messages = history.map((msg) {
      return ChatMessage(
        text: msg['content'],
        isUser: msg['role'] == 'user',
        imagePath: null,
        isSearch: false,
      );
    }).toList();

    // Update or create chat with the new conversation
    final existingChatIndex = _chats.indexWhere((chat) => chat.id == conversationId);
    if (existingChatIndex >= 0) {
      _chats[existingChatIndex] = _chats[existingChatIndex].copyWith(
        messages: messages,
      );
    } else {
      _chats.add(Chat(
        id: conversationId,
        title: 'Chat $conversationId',
        messages: messages,
      ));
    }

    _currentChatId = conversationId;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> sendMessage(String message) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentChat = this.currentChat;
      if (currentChat == null) {
        await createNewChat();
        return null;
      }

      final response = await _apiService.sendMessage(
        message,
        conversationId: int.tryParse(currentChat.id),
      );

      _updateChatWithResponse(response);
      _isLoading = false;
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> performSearch(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentChat = this.currentChat;
      if (currentChat == null) {
        await createNewChat();
        return null;
      }

      final response = await _apiService.sendMessage(
        query,
        isSearch: true,
        conversationId: int.tryParse(currentChat.id),
      );

      _updateChatWithResponse(response);
      _isLoading = false;
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeImage(String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentChat = this.currentChat;
      if (currentChat == null) {
        await createNewChat();
        return null;
      }

      final response = await _apiService.sendImage(
        imagePath,
        conversationId: int.tryParse(currentChat.id),
      );

      _updateChatWithResponse(response);
      _isLoading = false;
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> createNewChat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage('Start new chat');
      if (response['status'] == 'success') {
        _updateChatWithResponse(response);
      } else {
        throw Exception('Failed to create new chat: ${response['message']}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchChat(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = _chats.where((chat) => chat.id != chatId).toList();
      
      if (_chats.isEmpty) {
        await createNewChat();
      } else {
        _currentChatId = _chats.first.id;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateChatTitle(String chatId, String newTitle) async {
    _chats = _chats.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(title: newTitle);
      }
      return chat;
    }).toList();
    notifyListeners();
  }

  Future<void> clearCurrentChat() async {
    final currentChat = this.currentChat;
    if (currentChat == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await createNewChat();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
} 