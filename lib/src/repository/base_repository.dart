import '../core/mvc_exception.dart';
import '../core/mvc_model.dart';
import '../dependency/service_locator.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

/// Base repository class that encapsulates REST data access for a model type [T].
///
/// Implements standard CRUD operations and custom query methods.
abstract class BaseRepository<T> {
  /// The base API endpoint associated with this resource (e.g. '/users').
  final String endpoint;

  /// Optional model parser function used for deserializing JSON into [T].
  final JsonParser<T>? parser;

  /// Optional client instance explicitly passed for this repository.
  final ApiClient? customClient;

  const BaseRepository(
    this.endpoint, {
    this.parser,
    this.customClient,
  });

  /// Retrieves the active [ApiClient], either from constructor injection
  /// or from the [ServiceLocator].
  ApiClient get client {
    final c = customClient;
    if (c != null) return c;
    if (ServiceLocator().isRegistered<ApiClient>()) {
      return ServiceLocator().get<ApiClient>();
    }
    throw const MVCException(
      'No ApiClient found. Either pass an ApiClient to the repository or initialize MVC via MVC.initialize().',
    );
  }

  /// Builds a full resource path given an optional subpath or resource ID.
  String pathFor([dynamic idOrPath]) {
    if (idOrPath == null) return endpoint;
    final sub = idOrPath.toString();
    if (sub.startsWith('/')) return '$endpoint$sub';
    return '$endpoint/$sub';
  }

  /// Fetches a list of [T] resources.
  Future<List<T>> getAll({
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    JsonParser<T>? customParser,
  }) async {
    final effectiveParser = customParser ?? parser;
    if (effectiveParser == null) {
      throw const MVCException('Cannot call getAll() without a valid JsonParser.');
    }

    final response = await client.get<List<T>>(
      endpoint,
      query: query,
      headers: headers,
      parser: (data) => MVCModel.fromJsonList<T>(data, effectiveParser),
    );
    return response.data;
  }

  /// Fetches a single [T] resource by its identifier.
  Future<T> getById(
    dynamic id, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    JsonParser<T>? customParser,
  }) async {
    final effectiveParser = customParser ?? parser;
    if (effectiveParser == null) {
      throw const MVCException('Cannot call getById() without a valid JsonParser.');
    }

    final response = await client.get<T>(
      pathFor(id),
      query: query,
      headers: headers,
      parser: (data) => effectiveParser(Map<String, dynamic>.from(data as Map)),
    );
    return response.data;
  }

  /// Creates a new [T] resource.
  Future<T> create(
    Map<String, dynamic> data, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    JsonParser<T>? customParser,
  }) async {
    final effectiveParser = customParser ?? parser;
    final response = await client.post<dynamic>(
      endpoint,
      body: data,
      query: query,
      headers: headers,
    );

    if (effectiveParser != null && response.data is Map) {
      return effectiveParser(Map<String, dynamic>.from(response.data as Map));
    }
    return response.data as T;
  }

  /// Updates an existing [T] resource via PUT.
  Future<T> update(
    dynamic id,
    Map<String, dynamic> data, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    JsonParser<T>? customParser,
  }) async {
    final effectiveParser = customParser ?? parser;
    final response = await client.put<dynamic>(
      pathFor(id),
      body: data,
      query: query,
      headers: headers,
    );

    if (effectiveParser != null && response.data is Map) {
      return effectiveParser(Map<String, dynamic>.from(response.data as Map));
    }
    return response.data as T;
  }

  /// Partially updates an existing [T] resource via PATCH.
  Future<T> patch(
    dynamic id,
    Map<String, dynamic> data, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    JsonParser<T>? customParser,
  }) async {
    final effectiveParser = customParser ?? parser;
    final response = await client.patch<dynamic>(
      pathFor(id),
      body: data,
      query: query,
      headers: headers,
    );

    if (effectiveParser != null && response.data is Map) {
      return effectiveParser(Map<String, dynamic>.from(response.data as Map));
    }
    return response.data as T;
  }

  /// Deletes a resource by its identifier.
  Future<ApiResponse<dynamic>> delete(
    dynamic id, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return client.delete<dynamic>(
      pathFor(id),
      query: query,
      headers: headers,
    );
  }

  /// Convenience helper to fetch a list of arbitrary type [R].
  Future<List<R>> getList<R>({
    String? path,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required JsonParser<R> parser,
  }) async {
    final targetPath = path != null ? pathFor(path) : endpoint;
    final response = await client.get<List<R>>(
      targetPath,
      query: query,
      headers: headers,
      parser: (data) => MVCModel.fromJsonList<R>(data, parser),
    );
    return response.data;
  }
}

/// Alias for [BaseRepository] matching the developer experience shown in docs.
typedef MVCRepository<T> = BaseRepository<T>;
