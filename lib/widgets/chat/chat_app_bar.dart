import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:chatbot_lini/providers/chat_provider.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);

    return AppBar(
      title: Text(chatProvider.currentChat?.title ?? 'New Chat'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => context.pushNamed('history'),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.pushNamed('settings'),
        ),
      ],
    );
  }
} 