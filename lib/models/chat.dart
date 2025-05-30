import 'package:chatbot_lini/models/message.dart';

class Chat{
   String conversationId = '-1';
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages = [];

  Chat({
    required this.conversationId,
    required this.title,
    required this.createdAt,
  });

  void addMessage(ChatMessage message){
    messages.add(message);
  }

  void deleteMessage(ChatMessage message){
    messages.remove(message);
  }
}