import 'package:chatbot_lini/models/chat.dart';
import 'package:chatbot_lini/models/chat_history.dart';
import 'package:chatbot_lini/models/message.dart';
import 'package:chatbot_lini/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HistoryProvider extends ChangeNotifier{
  final List<historyModel> _history = [];
  bool _isLoading = false;
  bool _isActiveChatLoading = false;
  bool get isActiveChatLoading => _isActiveChatLoading;
  bool get isLoading => _isLoading;
  List<historyModel> get history => _history;
  Chat activeChat = Chat(conversationId: '-1', title: '', createdAt: DateTime.now());
  int activeIndex = 0;
  void notifyListeners(){
    super.notifyListeners();
  }
  void updateConversationId(String conversationId){
    activeChat.conversationId = conversationId;
    notifyListeners();
  }
  Future<void> fetchActiveChat(BuildContext context,   String conversationId, String title) async {
    _isActiveChatLoading = true;
    notifyListeners();
   try{
    final prefs = await SharedPreferences.getInstance();
    final response = await ApiService(http.Client(), prefs).fetchChat(conversationId);

// [
// 	{
// 		"role": "user",
// 		"content": "hi",
// 		"timestamp": "2025-05-30T10:07:54.740347"
// 	},
// 	{
// 		"role": "assistant",
// 		"content": "Hi there! How can I help you today? 😊 \n\nDo you want to:\n\n*   **Chat about something?** (Tell me about your day, a hobby, a question you have...)\n*   **Get information?** (I can answer questions on a huge range of topics.)\n*   **Play a game?** (Like a trivia game or a word game?)\n*   **Just say hello?** \n\nLet me know what you'd like to do!",
// 		"timestamp": "2025-05-30T10:07:58.306387"
// 	}
// ]
List<ChatMessage> messages = [];
for (var e in response) {
  messages.add(ChatMessage(
    role: e['role'] as String,
    content: e['content'] as String,
    timestamp: DateTime.parse(e['timestamp'] as String)
  ));
}
activeChat = Chat(
  conversationId: conversationId,
  title: title,
  createdAt: DateTime.parse(response[0]['timestamp'] as String)
);
activeChat.messages.addAll(messages);
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chat loaded successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    _isActiveChatLoading = false;
    notifyListeners();

  }
  void setActiveIndex(int index){
    activeIndex = index;
    notifyListeners();
  }
  void addHistory(historyModel history){
    _history.add(history);
  }
  Future<void> fetchHistory(BuildContext context) async {
    _isLoading = true;
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    try{

    
    final response = await ApiService(http.Client(), prefs).fetchHistory(context);
    _history.addAll(response);
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    _isLoading = false;
    notifyListeners();
  }

}