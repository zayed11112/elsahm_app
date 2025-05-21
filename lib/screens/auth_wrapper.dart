import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
// ThemeProvider is no longer needed here as the button is in AccountScreen
import 'login_screen.dart'; // Import LoginScreen
import 'account_screen.dart'; // Import the actual AccountScreen

// Removed the placeholder ProfileScreen class definition


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    print("AuthWrapper build: Status = ${authProvider.status}"); // Debug print

    switch (authProvider.status) {
      case AuthStatus.uninitialized:
      case AuthStatus.authenticating:
        // Show a loading indicator while checking auth state or logging in/out
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        // User is logged in, show the actual account screen
        return const AccountScreen();
      case AuthStatus.unauthenticated:
        // User is logged out, show the login screen
        // Consider using Navigator for Login/Signup flow within this tab
        // For simplicity now, just showing LoginScreen directly.
        return const LoginScreen();
    }
  }
}
