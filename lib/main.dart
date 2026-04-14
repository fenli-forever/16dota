import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '16dota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8A020),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        useMaterial3: true,
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return switch (auth.state) {
      AuthState.unknown   => const Scaffold(
          backgroundColor: Color(0xFF0D1117),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFE8A020)),
          ),
        ),
      AuthState.loggedOut => const LoginScreen(),
      AuthState.loggedIn  => const HomeScreen(),
    };
  }
}
