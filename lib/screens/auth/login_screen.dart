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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Container(),
     backgroundColor: Colors.transparent,
     actions: [
      IconButton(onPressed: (){context.push('/admin-login');}, icon: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text("Admin Login", style: TextStyle(color: Colors.black),))),
     ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
               
                Text(

                 isLogin? 'Welcome Back' : "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                isLogin?  'Sign in to continue' : "Sign Up To Continue",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AuthForm(
                  isLoading: authProvider.isLoading,
                  error: authProvider.error,
                  isLogin: isLogin,
                  onSubmit: (username, password, context,name ,contact) async {
                    if (isLogin) {
                      await authProvider.login(username, password, context);
                    } else {
                      await authProvider.register(username, password, context, name,contact);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
                  },
                  child:  Text(isLogin ?  'Don\'t have an account? Sign up' : "Already have an account? Sign in",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
} 