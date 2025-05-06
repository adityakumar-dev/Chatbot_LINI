import 'package:chatbot_lini/screens/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:chatbot_lini/providers/auth_provider.dart';
import 'package:chatbot_lini/widgets/auth/auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AuthForm(
                  isLoading: authProvider.isLoading,
                  error: authProvider.error,
                  onSubmit: (username, password, context) async {
                    await authProvider.login(username, password, context);
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.go('/register');
                  },
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 