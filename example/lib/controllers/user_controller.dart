import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Controller coordinating User domain logic and View presentation state.
class UserController extends MVCController<List<User>> {
  final UserRepository repository;

  UserController({UserRepository? repository})
      : repository = repository ?? UserRepository();

  @override
  void onReady() {
    super.onReady();
    // Fetch users automatically once UI frame is ready
    loadUsers();
  }

  /// Loads users using the repository with built-in loading and error management.
  Future<void> loadUsers() async {
    await execute(
      () => repository.getUsers(),
      loadingMessage: 'Fetching team members...',
    );
  }

  /// Creates a new user and appends to the current list.
  Future<bool> addUser({
    required String name,
    required String email,
    String role = 'Member',
  }) async {
    try {
      final newUser = await repository.createUser(
        name: name,
        email: email,
        role: role,
      );

      final currentUsers = List<User>.from(state.dataOrNull ?? []);
      currentUsers.insert(0, newUser);
      setSuccess(currentUsers);
      return true;
    } catch (e, st) {
      setError(e, st);
      return false;
    }
  }

  /// Removes a user and updates state.
  Future<void> removeUser(int id) async {
    try {
      await repository.removeUser(id);
      final currentUsers = List<User>.from(state.dataOrNull ?? []);
      currentUsers.removeWhere((u) => u.id == id);
      setSuccess(currentUsers);
    } catch (e, st) {
      setError(e, st);
    }
  }
}
