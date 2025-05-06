import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot_lini/providers/chat_provider.dart';
import 'package:chatbot_lini/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userMessage = _messageController.text.trim();
    _messageController.clear();

    try {
      // Send message and wait for response
      final response = await chatProvider.sendMessage(userMessage);
      if (response != null && response['status'] == 'success') {
        // The ChatProvider will handle updating the entire conversation
        // We just need to scroll to bottom after the update
        _scrollToBottom();
      }
    } catch (e) {
      // Error is handled by ChatProvider
      _scrollToBottom();
    }
  }

  Future<void> _performWebSearch() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final searchQuery = _messageController.text.trim();
    _messageController.clear();

    try {
      // Perform search and wait for response
      final response = await chatProvider.performSearch(searchQuery);
      if (response != null && response['status'] == 'success') {
        // The ChatProvider will handle updating the entire conversation
        // We just need to scroll to bottom after the update
        _scrollToBottom();
      }
    } catch (e) {
      // Error is handled by ChatProvider
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      // Send image and wait for response
      final response = await chatProvider.analyzeImage(image.path);
      if (response != null && response['status'] == 'success') {
        // The ChatProvider will handle updating the entire conversation
        // We just need to scroll to bottom after the update
        _scrollToBottom();
      }
    } catch (e) {
      // Error is handled by ChatProvider
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(chatProvider.currentChat?.title ?? 'New Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => chatProvider.clearCurrentChat(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.username?[0].toUpperCase() ?? 'U',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.username ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Chat'),
              onTap: () {
                chatProvider.createNewChat();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ...chatProvider.chats.map((chat) => ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(chat.title),
                  selected: chat.id == chatProvider.currentChatId,
                  onTap: () {
                    chatProvider.switchChat(chat.id);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.currentChat?.messages.length ?? 0,
              itemBuilder: (context, index) {
                final message = chatProvider.currentChat!.messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(message.imagePath!),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (message.imagePath != null)
                          const SizedBox(height: 8),
                        SelectableText(
                          message.text,
                          style: TextStyle(
                            color: message.isUser
                                ? Colors.white
                                : theme.colorScheme.onSecondaryContainer,
                            fontSize: 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (chatProvider.isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performWebSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 