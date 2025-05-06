import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatbot_lini/providers/chat_provider.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isRecording = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.addMessage(
      ChatMessage(
        text: 'Analyze this image',
        isUser: true,
        imagePath: image.path,
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() => _isRecording = true);
    // TODO: Implement voice recording
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    // TODO: Implement voice recording stop and message sending
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(
      ChatMessage(
        text: text,
        isUser: true,
      ),
    );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
            ),
            IconButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              color: _isRecording ? theme.colorScheme.error : null,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
} 