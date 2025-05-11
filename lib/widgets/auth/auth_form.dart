import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthForm extends StatefulWidget {
  final bool isLoading;
  final String? error;
  final bool isLogin;
  final Function(String username, String password, BuildContext context, String? name, String? contact) onSubmit;

  const AuthForm({
    super.key,
    required this.isLoading,
    this.error,
    this.isLogin = true,
    required this.onSubmit,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        context,
        widget.isLogin ? null : _nameController.text.trim(),
        widget.isLogin ? null : _contactController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!widget.isLogin)
          Column(
            children: [
 TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
           
          ), TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Contact',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
           
          ),
            ],
          ),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            // validator: (value) {
            //   if (value == null || value.isEmpty) {
            //     return 'Please enter your username';
            //   }
            //   if (value.length < 3) {
            //     return 'Username must be at least 3 characters';
            //   }
            //   return null;
            // },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            // validator: (value) {
            //   if (value == null || value.isEmpty) {
            //     return 'Please enter your password';
            //   }
            //   if (value.length < 6) {
            //     return 'Password must be at least 6 characters';
            //   }
            //   return null;
            // },
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submit,
              child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.isLogin ? 'Login' : 'Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
} 