import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:chatbot_lini/providers/history_provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HistoryProvider>(context, listen: false);
      provider.fetchHistory(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Chat History'),
          ),
          body: historyProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : historyProvider.history.isEmpty
                  ? const Center(child: Text("No chat history found."))
                  : ListView.separated(
                      itemCount: historyProvider.history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = historyProvider.history[index];
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(chat.title),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jm().format(chat.created_at),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            historyProvider.setActiveIndex(index);
                            historyProvider.fetchActiveChat(context, chat.conversation_id.toString(), chat.title);
                            context.push('/user-chat');
                          },
                        );
                      },
                    ),

                    floatingActionButton: FloatingActionButton(
                      onPressed: () {
                        // historyProvider.clearHistory();
                        historyProvider.setActiveIndex(-1);
                        historyProvider.activeChat.messages.clear();
                        historyProvider.activeChat.conversationId = '-1';
                        
                        context.push('/user-chat');
                        
                        // historyProvider.fetchActiveChat(context, chat.conversation_id.toString(), chat.title);
                      },
                      backgroundColor: Colors.blueAccent,
                      child: const Icon(Icons.add, color: Colors.white, size: 30,),
                    ),
        );
      },
    );
  }
}
