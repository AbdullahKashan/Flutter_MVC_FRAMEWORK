import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';

// Test model
class TestUser extends MVCModel {
  final int id;
  final String name;
  final String email;

  const TestUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TestUser.fromJson(Map<String, dynamic> json) => TestUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TestUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// Test repository
class TestUserRepository extends BaseRepository<TestUser> {
  TestUserRepository({super.customClient})
      : super('/users', parser: TestUser.fromJson);
}

// Test controller
class TestUserController extends MVCController<List<TestUser>> {
  final TestUserRepository repository;

  TestUserController(this.repository);

  Future<void> fetchUsers() async {
    await execute(() => repository.getAll());
  }
}

void main() {
  setUp(() {
    MVC.reset();
  });

  tearDown(() {
    MVC.reset();
  });

  group('RequestState', () {
    test('State properties and getters', () {
      const idle = RequestState<String>.idle();
      expect(idle.isIdle, isTrue);
      expect(idle.isLoading, isFalse);
      expect(idle.dataOrNull, isNull);

      const loading = RequestState<String>.loading(message: 'Please wait');
      expect(loading.isLoading, isTrue);
      expect(loading.messageOrNull, equals('Please wait'));

      const success = RequestState<String>.success('Hello');
      expect(success.isSuccess, isTrue);
      expect(success.dataOrNull, equals('Hello'));

      const error = RequestState<String>.error('An error');
      expect(error.isError, isTrue);
      expect(error.errorOrNull, equals('An error'));
    });

    test('Pattern matching with when and maybeWhen', () {
      const state = RequestState<int>.success(42);

      final val = state.when(
        idle: () => 0,
        loading: (msg, prog) => 1,
        success: (d) => d * 2,
        error: (err, st) => -1,
      );
      expect(val, equals(84));

      final maybeVal = state.maybeWhen(
        success: (d) => d + 1,
        orElse: () => 0,
      );
      expect(maybeVal, equals(43));
    });
  });

  group('MVCModel', () {
    test('Serializes and deserializes from JSON list', () {
      const user = TestUser(id: 1, name: 'Alice', email: 'alice@example.com');
      final json = user.toJson();
      expect(json['id'], equals(1));
      expect(user.toJsonString(), contains('"name":"Alice"'));

      final listJson = [
        {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
        {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
      ];

      final users = MVCModel.fromJsonList<TestUser>(listJson, TestUser.fromJson);
      expect(users.length, equals(2));
      expect(users.first.name, equals('Alice'));
    });
  });

  group('ServiceLocator', () {
    test('Registers and resolves instances', () {
      final sl = ServiceLocator();
      sl.register<String>('Hello World');

      expect(sl.isRegistered<String>(), isTrue);
      expect(sl.get<String>(), equals('Hello World'));

      sl.unregister<String>();
      expect(sl.isRegistered<String>(), isFalse);
      expect(() => sl.get<String>(), throwsA(isA<DependencyNotFoundException>()));
    });

    test('Lazy singletons and factories', () {
      final sl = ServiceLocator();
      var count = 0;
      sl.registerLazySingleton<int>(() => ++count);

      expect(count, equals(0));
      expect(sl.get<int>(), equals(1));
      expect(sl.get<int>(), equals(1)); // singleton retained

      var factoryCount = 0;
      sl.registerFactory<double>(() => (++factoryCount).toDouble());
      expect(sl.get<double>(), equals(1.0));
      expect(sl.get<double>(), equals(2.0));
    });
  });

  group('Storage', () {
    test('MemoryStorage reads, writes, and clears data', () async {
      final storage = MemoryStorage();
      await storage.write('token', 'abc123xyz');
      expect(await storage.read('token'), equals('abc123xyz'));
      expect(await storage.containsKey('token'), isTrue);

      await storage.writeJson('profile', {'name': 'Antigravity'});
      final profile = await storage.readJson('profile');
      expect(profile?['name'], equals('Antigravity'));

      await storage.delete('token');
      expect(await storage.containsKey('token'), isFalse);

      await storage.clear();
      expect(await storage.readJson('profile'), isNull);
    });
  });

  group('Auth & Token Management', () {
    test('TokenManager saves, reads, and clears tokens', () async {
      final tokenManager = TokenManager();
      await tokenManager.saveTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );

      final tokens = await tokenManager.getTokens();
      expect(tokens?.accessToken, equals('access-123'));
      expect(tokens?.refreshToken, equals('refresh-456'));
      expect(await tokenManager.hasValidToken(), isTrue);

      await tokenManager.clearTokens();
      expect(await tokenManager.hasValidToken(), isFalse);
    });

    test('AuthManager coordinates login and logout', () async {
      final auth = AuthManager();
      await auth.initialize();
      expect(auth.isUnauthenticated, isTrue);

      await auth.login(const TokenPair(accessToken: 'token-abc'));
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isUnauthenticated, isTrue);
    });

    test('AuthManager concurrent refresh mutex', () async {
      var refreshCount = 0;
      final auth = AuthManager(
        onRefreshToken: (refreshToken, client) async {
          refreshCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const TokenPair(accessToken: 'new-token');
        },
      );

      await auth.tokenManager.saveTokens(
        accessToken: 'old-token',
        refreshToken: 'old-refresh',
      );

      final client = ApiClient(config: const ApiConfig(baseUrl: 'https://example.com'));

      // Fire 3 simultaneous refresh calls
      final results = await Future.wait([
        auth.refreshToken(client),
        auth.refreshToken(client),
        auth.refreshToken(client),
      ]);

      expect(refreshCount, equals(1));
      expect(results[0]?.accessToken, equals('new-token'));
      expect(results[1]?.accessToken, equals('new-token'));
      expect(results[2]?.accessToken, equals('new-token'));
    });
  });

  group('ApiClient & Interceptors', () {
    test('Successful GET and POST with mock client', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/users') {
          return http.Response(
            jsonEncode([
              {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'}
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' && request.url.path == '/api/v1/users') {
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({'id': 2, 'name': body['name'], 'email': body['email']}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test.com/api/v1'),
        httpClient: mockClient,
      );

      final getResponse = await client.get<List<TestUser>>(
        '/users',
        parser: (d) => MVCModel.fromJsonList(d, TestUser.fromJson),
      );
      expect(getResponse.isSuccess, isTrue);
      expect(getResponse.data.first.name, equals('John Doe'));

      final postResponse = await client.post<TestUser>(
        '/users',
        body: {'name': 'Jane Doe', 'email': 'jane@example.com'},
        parser: (d) => TestUser.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      expect(postResponse.data.id, equals(2));
      expect(postResponse.data.name, equals('Jane Doe'));
    });

    test('ApiException mapping on HTTP 404 and 500', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/missing')) {
          return http.Response(
            jsonEncode({'message': 'Resource not found'}),
            404,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Internal Server Error', 500);
      });

      final client = ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test.com'),
        httpClient: mockClient,
      );

      expect(
        () => client.get<dynamic>('/missing'),
        throwsA(isA<NotFoundException>().having((e) => e.statusCode, 'statusCode', 404)),
      );

      expect(
        () => client.get<dynamic>('/crash'),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('Multipart upload handles byte payloads', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['content-type'], contains('multipart/form-data'));
        return http.Response(jsonEncode({'status': 'uploaded'}), 200,
            headers: {'content-type': 'application/json'});
      });

      final client = ApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test.com'),
        httpClient: mockClient,
      );

      final payload = MultipartPayload(
        fields: {'title': 'Avatar'},
        files: [
          MultipartFileItem.fromString('file', 'test-content', filename: 'test.txt'),
        ],
      );

      final response = await client.upload<Map<String, dynamic>>(
        '/upload',
        payload: payload,
      );
      expect(response.isSuccess, isTrue);
      expect(response.data['status'], equals('uploaded'));
    });
  });

  group('BaseRepository & MVCController', () {
    test('Repository and Controller integration', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
            {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await MVC.initialize(
        baseUrl: 'https://api.example.com',
        httpClient: mockClient,
      );

      final repo = TestUserRepository();
      final controller = TestUserController(repo);

      expect(controller.state.isIdle, isTrue);

      await controller.fetchUsers();

      expect(controller.state.isSuccess, isTrue);
      final users = controller.state.dataOrNull!;
      expect(users.length, equals(2));
      expect(users.first.name, equals('Alice'));

      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });
  });

  group('PaginationController', () {
    test('Loads initial page and subsequent pages', () async {
      final controller = PaginationController<String>(
        autoLoad: false,
        pageSize: 2,
        fetcher: (page, pageSize) async {
          if (page == 1) {
            return const PaginatedResponse(
              items: ['Item 1', 'Item 2'],
              page: 1,
              pageSize: 2,
              hasMore: true,
            );
          } else {
            return const PaginatedResponse(
              items: ['Item 3'],
              page: 2,
              pageSize: 2,
              hasMore: false,
            );
          }
        },
      );

      await controller.loadInitial();
      expect(controller.items, equals(['Item 1', 'Item 2']));
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.items, equals(['Item 1', 'Item 2', 'Item 3']));
      expect(controller.hasMore, isFalse);

      controller.dispose();
    });
  });

  group('Widgets (MVCBuilder, LoadingView, ErrorView)', () {
    testWidgets('MVCBuilder displays loading, success, and error states',
        (tester) async {
      final controller = MVCController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MVCBuilder<MVCController<String>, String>(
              controller: controller,
              onIdle: (context) => const Text('Idle View'),
              onLoading: (context, msg, progress) => const Text('Loading View'),
              onSuccess: (context, data) => Text('Data: $data'),
              onError: (context, error, _) => Text('Error: $error'),
            ),
          ),
        ),
      );

      expect(find.text('Idle View'), findsOneWidget);

      controller.setLoading();
      await tester.pump();
      expect(find.text('Loading View'), findsOneWidget);

      controller.setSuccess('Loaded successfully!');
      await tester.pump();
      expect(find.text('Data: Loaded successfully!'), findsOneWidget);

      controller.setError('Something broke');
      await tester.pump();
      expect(find.text('Error: Something broke'), findsOneWidget);
    });

    testWidgets('ErrorView triggers onRetry callback when tapped',
        (tester) async {
      var retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Failed to connect',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retryTapped, isTrue);
    });
  });
}
