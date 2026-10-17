# flutter_mvc_framework

[![pub package](https://img.shields.io/pub/v/flutter_mvc_framework.svg)](https://pub.dev/packages/flutter_mvc_framework)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter)](https://flutter.dev)
[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://dart.dev/guides/language/effective-dart)

A battle-tested, modular, and batteries-included **Model-View-Controller (MVC)** framework for Flutter applications. Designed for enterprise production apps, it provides reactive state management, an industrial-strength REST API client, automated JWT authentication with token refresh, repository abstractions, infinite pagination, and reusable view components with zero boilerplate.

---

## 💡 Why flutter_mvc_framework? (Benefits & Rationale)

In many Flutter state management packages and custom architectures, code quickly degrades into **"God Classes"** where the controller handles HTTP requests, parses raw JSON, holds JWT tokens in memory, logs errors, and drives the widget tree.

`flutter_mvc_framework` solves this by enforcing clean, scalable separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                         VIEW                           │
│           (MVCView, MVCBuilder, Widgets)               │
└──────────────────────────┬─────────────────────────────┘
                           │ Listens to State & Triggers Actions
                           ▼
┌────────────────────────────────────────────────────────┐
│                      CONTROLLER                        │
│      (MVCController, PaginationController, State)      │
└──────────────────────────┬─────────────────────────────┘
                           │ Invokes Business Methods
                           ▼
┌────────────────────────────────────────────────────────┐
│                      REPOSITORY                        │
│           (BaseRepository / MVCRepository)             │
└──────────────────────────┬─────────────────────────────┘
                           │ Dispatches REST Calls & Parses JSON
                           ▼
┌────────────────────────────────────────────────────────┐
│                      API CLIENT                        │
│         (Interceptors, AuthManager, Storage)           │
└────────────────────────────────────────────────────────┘
```

### Key Benefits

1. **Anti-Monolith Architecture**:
   Controllers remain focused exclusively on UI state and event coordination. Repositories handle data access and API endpoints. The API Client handles HTTP transports, interceptors, and tokens.
2. **Race-Condition-Proof Token Refreshing**:
   Most custom auth interceptors fail when multiple concurrent requests trigger 401 Unauthorized simultaneously, firing 5 duplicate refresh requests. `flutter_mvc_framework` features a built-in **concurrency mutex** that merges all concurrent 401 requests into a single in-flight token refresh.
3. **Type-Safe Sealed Request States**:
   Eliminates error-prone boolean flags (`bool isLoading = false;`). Instead, [RequestState<T>] provides exhaustive pattern matching (`when`, `maybeWhen`, `map`) across `idle`, `loading`, `success`, and `error`.
4. **Standardized Exception Hierarchy**:
   Never catch generic exceptions again. Use typed exceptions like `UnauthorizedException`, `ValidationException` (with parsed field errors), `NotFoundException`, and `NetworkException`.
5. **Zero External Dependencies**:
   Built on standard Flutter and cross-platform `http`. No bulky dependencies, no code-generation requirements, and fast compilation.

---

## 🛠️ Reliable Use & Best Practices

To get the most reliability out of `flutter_mvc_framework` in production:

1. **Initialize Early**: Call `await MVC.initialize(...)` in `main()` before rendering the root widget.
2. **One Model per Resource**: Extend `MVCModel` and keep JSON parsing in factories: `factory MyModel.fromJson(Map<String, dynamic> json)`.
3. **Use Repositories for All Network Traffic**: Never make direct `http.get` calls inside widgets or UI listeners. Pass all operations through your typed `BaseRepository<T>`.
4. **Prefer `execute()` in Controllers**: When triggering async actions in your controller, wrap them in `execute(() => repository.fetch())`. It automatically manages the loading, success, and error states for you.
5. **Leverage `MVCBuilder` for Reactive Views**: Avoid manually calling `setState()` or checking `controller.isLoading`. Use `MVCBuilder` with `onSuccess`, `onLoading`, and `onError` handlers.

---

## 📦 Installation

Add `flutter_mvc_framework` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_mvc_framework: ^1.0.0
```

Install via terminal:

```bash
flutter pub get
```

---

## 🚀 Quick Start Guide

### 1. Initialize the Framework

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MVC.initialize(
    baseUrl: 'https://api.example.com/v1',
    logging: true, // Enables formatted HTTP network logs
    auth: const AuthConfig(
      refreshEndpoint: '/auth/refresh',
      tokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
    ),
  );

  runApp(const MyApp());
}
```

---

### 2. Define Your Model

```dart
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';

class User extends MVCModel {
  final int id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
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
}
```

---

### 3. Create the Repository

```dart
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';
import 'user.dart';

class UserRepository extends BaseRepository<User> {
  UserRepository() : super('/users', parser: User.fromJson);

  Future<List<User>> getUsers() => getAll();

  Future<User> getUser(int id) => getById(id);

  Future<User> createUser(String name, String email) {
    return create({'name': name, 'email': email});
  }

  Future<void> removeUser(int id) => delete(id);
}
```

---

### 4. Create the Controller

```dart
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';
import 'user.dart';
import 'user_repository.dart';

class UserController extends MVCController<List<User>> {
  final UserRepository repository;

  UserController({UserRepository? repository})
      : repository = repository ?? UserRepository();

  @override
  void onReady() {
    super.onReady();
    loadUsers();
  }

  Future<void> loadUsers() async {
    await execute(
      () => repository.getUsers(),
      loadingMessage: 'Loading team members...',
    );
  }

  Future<void> addUser(String name, String email) async {
    try {
      final newUser = await repository.createUser(name, email);
      final current = List<User>.from(state.dataOrNull ?? []);
      setSuccess([newUser, ...current]);
    } catch (e, st) {
      setError(e, st);
    }
  }
}
```

---

### 5. Build the View

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';
import 'user_controller.dart';
import 'user.dart';

class UserListView extends MVCView<UserController> {
  const UserListView({super.key});

  @override
  UserController createController(BuildContext context) => UserController();

  @override
  MVCViewState<UserController, UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends MVCViewState<UserController, UserListView> {
  @override
  Widget buildView(BuildContext context, UserController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: MVCBuilder<UserController, List<User>>(
        controller: controller,
        onLoading: (context, message, progress) => LoadingView(message: message),
        onError: (context, error, _) => ErrorView(
          error: error,
          onRetry: () => controller.loadUsers(),
        ),
        onSuccess: (context, users) {
          return RefreshIndicator(
            onRefresh: () => controller.loadUsers(),
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

## ⚡ Advanced Capabilities

### 1. Infinite Scrolling & Pagination

`PaginationController<T>` simplifies cursor or page-based pagination without losing existing data during background fetches:

```dart
final controller = PaginationController<User>(
  pageSize: 20,
  fetcher: (page, pageSize) async {
    final response = await MVC.api.get<Map<String, dynamic>>(
      '/users',
      query: {'page': page, 'limit': pageSize},
    );
    return PaginatedResponse.fromJson(response.data, User.fromJson);
  },
);

// Trigger next page when scrolling reaches threshold
controller.loadMore();
```

---

### 2. File Uploads (Multipart/Form-Data)

```dart
final payload = MultipartPayload(
  fields: {'folder': 'profile_pictures'},
  files: [
    MultipartFileItem.fromBytes(
      'file',
      avatarBytes,
      filename: 'profile.jpg',
      contentType: 'image/jpeg',
    ),
  ],
);

final response = await MVC.api.upload<Map<String, dynamic>>(
  '/users/upload-avatar',
  payload: payload,
);
```

---

### 3. Dependency Injection (Service Locator)

Built-in type-safe dependency locator accessible anywhere in your app:

```dart
// Register
MVC.register<AnalyticsService>(AnalyticsService());
MVC.registerLazySingleton<DatabaseService>(() => DatabaseService());
MVC.registerFactory<UserController>(() => UserController());

// Resolve
final analytics = MVC.locate<AnalyticsService>();
```

---

### 4. Custom Interceptors

```dart
class AppHeaderInterceptor extends Interceptor {
  @override
  FutureOr<RequestOptions> onRequest(RequestOptions options) {
    final headers = Map<String, String>.from(options.headers);
    headers['X-Client-Platform'] = 'Flutter';
    return options.copyWith(headers: headers);
  }
}

await MVC.initialize(
  baseUrl: 'https://api.example.com',
  interceptors: [AppHeaderInterceptor()],
);
```

---

## 🧪 Testing

The framework is 100% testable using standard `MockClient`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';

void main() {
  test('Fetches team members', () async {
    final mock = MockClient((req) async {
      return http.Response('[{"id": 1, "name": "Antigravity", "email": "ai@deepmind.com"}]', 200);
    });

    await MVC.initialize(
      baseUrl: 'https://api.example.com',
      httpClient: mock,
    );

    final repo = UserRepository();
    final users = await repo.getUsers();

    expect(users.length, equals(1));
    expect(users.first.name, equals('Antigravity'));
  });
}
```

---

## 📄 License

This package is open source and released under the [MIT License](LICENSE).
