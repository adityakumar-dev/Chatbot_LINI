import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:chatbot_lini/providers/auth_provider.dart';
import 'package:chatbot_lini/widgets/auth/auth_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => context.push('/admin-login'),
              style: TextButton.styleFrom(
                foregroundColor: colors.onPrimary,
                backgroundColor: colors.primary.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.primary.withOpacity(0.5)),
                ),
              ),
              child: const Text('Admin Login'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withOpacity(0.9),
              colors.primary.withOpacity(0.7),
              colors.primary.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or App Icon
                    Material(
                      color: Colors.transparent,
                      child: Image.asset('assets/images/logo.png', width: 100, height: 100,color: Colors.white,  ),)
,                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      isLogin ? 'Welcome Back' : "Create Account",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      isLogin ? 'Sign in to continue' : "Sign Up To Continue",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimary.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Auth Form
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AuthForm(
                          isLoading: authProvider.isLoading,
                          error: authProvider.error,
                          isLogin: isLogin,
                          onSubmit: (username, password, context, name, contact, speciality, address, required_needs) async {
                            if (_formKey.currentState!.validate()) {
                              if (isLogin) {
                                await authProvider.login(username, password, context);
                              } else {
                                await authProvider.register(
                                  username, 
                                  password, 
                                  context, 
                                  name,
                                  contact,
                                  speciality,
                                  address,
                                  required_needs
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Toggle between login/signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin ? 'Don\'t have an account?' : "Already have an account?",
                          style: TextStyle(
                            color: colors.onPrimary.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isLogin ? 'Sign up' : "Sign in",
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                              // decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}