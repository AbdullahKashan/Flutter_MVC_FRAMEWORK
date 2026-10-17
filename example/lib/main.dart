import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'controllers/user_controller.dart';
import 'repositories/user_repository.dart';
import 'views/user_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In-memory demo data for standalone execution
  final List<Map<String, dynamic>> demoUsers = [
    {
      'id': 1,
      'name': 'Sarah Connor',
      'email': 'sarah@skynet.dev',
      'role': 'Admin',
    },
    {
      'id': 2,
      'name': 'Alex Rivera',
      'email': 'alex.rivera@example.com',
      'role': 'Developer',
    },
    {
      'id': 3,
      'name': 'Emma Watson',
      'email': 'emma.watson@design.co',
      'role': 'Designer',
    },
  ];

  // Mock HTTP client demonstrating simulated network latency and realistic REST responses
  final mockClient = MockClient((request) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (request.method == 'GET' && request.url.path.endsWith('/users')) {
      return http.Response(
        jsonEncode(demoUsers),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request.method == 'POST' && request.url.path.endsWith('/users')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final newUser = {
        'id': demoUsers.length + 1,
        'name': body['name'],
        'email': body['email'],
        'role': body['role'] ?? 'Member',
      };
      demoUsers.insert(0, newUser);
      return http.Response(
        jsonEncode(newUser),
        201,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request.method == 'DELETE' && request.url.path.contains('/users/')) {
      final id = int.tryParse(request.url.pathSegments.last);
      demoUsers.removeWhere((u) => u['id'] == id);
      return http.Response(jsonEncode({'status': 'deleted'}), 200);
    }

    return http.Response('Not Found', 404);
  });

  // Initialize the flutter_mvc framework
  await MVC.initialize(
    baseUrl: 'https://api.example.com/v1',
    logging: true,
    httpClient: mockClient,
  );

  // Register dependencies in the ServiceLocator
  MVC.register<UserRepository>(UserRepository());
  MVC.registerFactory<UserController>(() => UserController());

  runApp(const FlutterMvcExampleApp());
}

class FlutterMvcExampleApp extends StatelessWidget {
  const FlutterMvcExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MVC Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const UserListView(),
    );
  }
}
