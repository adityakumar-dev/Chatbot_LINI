import 'package:flutter/material.dart';
import 'package:chatbot_lini/services/api_service.dart';
import 'package:go_router/go_router.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _username;

  AuthProvider(this._apiService) {
    checkAuth();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  Future<bool> login(String username, String password, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      if (response['success']) {
        _isAuthenticated = true;
        _username = username;
        _showSuccessDialog(context, 'Welcome Back!', 'You have successfully logged in.', () {
          context.go('/chat');
        });
        return true;
      } else {
        _error = response['message'];
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(username, password);
      if (response['success']) {
        _isAuthenticated = true;
        _username = username;
        _showSuccessDialog(context, 'Welcome!', 'Your account has been created successfully.', () {
          context.go('/chat');
        });
        return true;
      } else {
        _error = response['message'];
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message, VoidCallback onComplete) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onComplete();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _isAuthenticated = false;
      _username = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _apiService.checkAuth();
      if (_isAuthenticated) {
        _username = 'User'; // Default username until we get it from the API
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _username = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 