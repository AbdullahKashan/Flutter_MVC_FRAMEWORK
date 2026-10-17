import 'package:flutter_mvc_framework/flutter_mvc_framework.dart';
import '../models/user.dart';

/// Repository handling User API endpoints.
class UserRepository extends BaseRepository<User> {
  UserRepository({super.customClient})
      : super('/users', parser: User.fromJson);

  /// Fetches a paginated or full list of users.
  Future<List<User>> getUsers({int? page, int? limit}) {
    final query = <String, dynamic>{};
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    return getAll(query: query.isNotEmpty ? query : null);
  }

  /// Fetches a single user by ID.
  Future<User> getUser(int id) {
    return getById(id);
  }

  /// Creates a new user record.
  Future<User> createUser({
    required String name,
    required String email,
    String role = 'Member',
  }) {
    return create({
      'name': name,
      'email': email,
      'role': role,
    });
  }

  /// Deletes a user by ID.
  Future<void> removeUser(int id) async {
    await delete(id);
  }
}
