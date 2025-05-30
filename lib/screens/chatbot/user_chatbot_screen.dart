import 'dart:convert';
import 'dart:io';

import 'package:chatbot_lini/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:chatbot_lini/models/message.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late HistoryProvider historyProvider;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<File> files = [];
  bool _isReceivingStream = false;
  String _streamBuffer = '';
  bool _isWebSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _isReceivingStream = true);

    final message = ChatMessage(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      historyProvider.activeChat.addMessage(message);
      _controller.clear();
    });

    _scrollToBottom();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    try {
      http.MultipartRequest request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/chat')
      );
      
      request.fields['query'] = text;
      if(historyProvider.activeChat.conversationId != '-1'){
      request.fields['conversation_id'] = historyProvider.activeChat.conversationId;
      }
      request.fields['is_search'] = _isWebSearch ? 'true' : 'false';
      request.fields['user_id'] = prefs.getString('user_id') ?? '';
      
      if (files.isNotEmpty) {
        for (var file in files) {
          request.files.add(await http.MultipartFile.fromPath('files', file.path));
        }
      }

      final streamedResponse = await request.send();
      _streamBuffer = '';
      
      ChatMessage assistantMessage = ChatMessage(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );

      setState(() {
        historyProvider.activeChat.addMessage(assistantMessage);
        _scrollToBottom();
      });

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // Split the chunks by "data: " as they come in SSE format
        for (var line in chunk.split('data: ')) {
          if (line.trim().isEmpty) continue;
          
          try {
            final data = jsonDecode(line);
            
            if (data.containsKey('metadata')) {
              // Handle metadata (new conversation)
              if (historyProvider.activeChat.conversationId == '-1') {
                setState(() {
                  historyProvider.updateConversationId(data['metadata']['conversation_id']);
                });
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('New conversation started' + data['metadata']['conversation_id'])),
                // );
              }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('New conversation started ${historyProvider.activeChat.conversationId}  '  + data['metadata']['conversation_id'])),
                );
              continue;
            }
            
            if (data.containsKey('content')) {
              _streamBuffer += data['content'];
              setState(() {
                // Replace the message with a new one containing updated content
                final updatedMessage = ChatMessage(
                  role: 'assistant',
                  content: _streamBuffer,
                  timestamp: assistantMessage.timestamp,
                );
                final messageIndex = historyProvider.activeChat.messages.indexOf(assistantMessage);
                if (messageIndex != -1) {
                  historyProvider.activeChat.messages[messageIndex] = updatedMessage;
                  assistantMessage = updatedMessage;
                }
                historyProvider.notifyListeners();
                _scrollToBottom();
              });
            }
          } catch (e) {
            print('Error parsing chunk: $e');
          }
        }
      }

      // Clear files after sending
      setState(() {
        files.clear();
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() => _isReceivingStream = false);
    }
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.blueAccent : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 12,
                      child: Text(
                        'AI',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 4),
              ],
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.Hm().format(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : Colors.black45,
                    ),
                  ),
                  if (!isUser) ...[
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () {}, // Copy text functionality to be implemented
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onImageUpload() async{
    ImagePicker imagePicker = ImagePicker();
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      files.add(File(image.path));
    
    setState(() {
      _isImageUpload = true;
    });
    }
  }


  bool _isLoading = false;
  bool _isImageUpload = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        historyProvider = provider;
        if (provider.isActiveChatLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(onPressed: () {
              historyProvider.fetchHistory(context);
              context.pop();
            }, icon: Icon(Icons.arrow_back)),
            title: Text(provider.activeChat.title),
            backgroundColor: Colors.white,
            elevation: 2,
          ),
          body: Column(
            children: [
              Expanded(
                child: provider.activeChat.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: provider.activeChat.messages.length,
                        itemBuilder: (context, index) =>
                            _buildMessage(provider.activeChat.messages[provider.activeChat.messages.length - 1 - index]),
                      ),
              ),
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (files.isNotEmpty) ...[
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ...files.map((file) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ImageWidget(
                        file: file,
                        onDelete: () => setState(() => files.remove(file)),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: _isReceivingStream ? null : () async {
                   _onImageUpload();
                  setState(() {});
                },
                color: _isReceivingStream ? Colors.grey : Colors.grey.shade600,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !_isReceivingStream,
                  onEditingComplete: _isReceivingStream ? null : () => _sendMessage(_controller.text),
                  decoration: InputDecoration(
                    hintText: _isReceivingStream ? "Receiving response..." : "Type a message...",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, 
                            color: _isWebSearch ? Colors.blueAccent : Colors.grey.shade600
                          ),
                          onPressed: _isReceivingStream ? null : () {
                            setState(() => _isWebSearch = !_isWebSearch);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _isReceivingStream ? Colors.grey : Colors.blueAccent,
                child: IconButton(
                  icon: _isReceivingStream 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isReceivingStream ? null : () => _sendMessage(_controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class ImageWidget extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;
  const ImageWidget({super.key, required this.file, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                onPressed: onDelete,
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}