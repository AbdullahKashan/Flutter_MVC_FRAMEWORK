import 'dart:async';
import 'package:flutter/foundation.dart';

import '../dependency/service_locator.dart';
import '../network/api_client.dart';
import 'mvc_exception.dart';
import 'request_state.dart';

/// Base controller in the flutter_mvc framework.
///
/// Encapsulates reactive state management, lifecycle callbacks,
/// and asynchronous operation helpers.
class MVCController<T> extends ChangeNotifier {
  RequestState<T> _state;
  bool _isDisposed = false;
  bool _isInitialized = false;

  MVCController({RequestState<T>? initialState})
      : _state = initialState ?? RequestState<T>.idle();

  /// Current reactive request state.
  RequestState<T> get state => _state;

  /// Whether the controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether [onInit] has been executed.
  bool get isInitialized => _isInitialized;

  /// Resolves the default [ApiClient] from [ServiceLocator] if registered.
  ApiClient get apiClient {
    if (ServiceLocator().isRegistered<ApiClient>()) {
      return ServiceLocator().get<ApiClient>();
    }
    throw const MVCException(
      'No ApiClient found in ServiceLocator. Call MVC.initialize() or register an ApiClient.',
    );
  }

  /// Lifecycle callback triggered when the controller is first instantiated or attached.
  @mustCallSuper
  void onInit() {
    _isInitialized = true;
  }

  /// Lifecycle callback triggered after the first frame has been rendered by the Flutter engine.
  @mustCallSuper
  void onReady() {}

  /// Lifecycle callback triggered right before the controller is disposed.
  @mustCallSuper
  void onDispose() {}

  @override
  void dispose() {
    if (!_isDisposed) {
      onDispose();
      _isDisposed = true;
      super.dispose();
    }
  }

  /// Safely notifies listeners only if the controller is still active.
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Updates the controller state and notifies listeners.
  void setState(RequestState<T> newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  /// Sets state to [IdleState].
  void setIdle() {
    setState(RequestState<T>.idle());
  }

  /// Sets state to [LoadingState].
  void setLoading({String? message, double? progress}) {
    setState(RequestState<T>.loading(message: message, progress: progress));
  }

  /// Sets state to [SuccessState] containing [data].
  void setSuccess(T data) {
    setState(RequestState<T>.success(data));
  }

  /// Sets state to [ErrorState] containing [error].
  void setError(dynamic error, [StackTrace? stackTrace]) {
    setState(RequestState<T>.error(error, stackTrace));
  }

  /// Executes an asynchronous operation, automatically managing [LoadingState],
  /// [SuccessState], and [ErrorState].
  Future<T?> execute(
    Future<T> Function() action, {
    bool notifyLoading = true,
    String? loadingMessage,
  }) async {
    if (notifyLoading) {
      setLoading(message: loadingMessage);
    }
    try {
      final result = await action();
      setSuccess(result);
      return result;
    } catch (error, stackTrace) {
      setError(error, stackTrace);
      return null;
    }
  }

  /// Convenience GET request delegating to [apiClient].
  Future<R> get<R>(
    String endpoint, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    R Function(dynamic data)? parser,
    bool updateState = false,
  }) async {
    if (updateState) setLoading();
    try {
      final response = await apiClient.get<R>(
        endpoint,
        query: query,
        headers: headers,
        parser: parser,
      );
      if (updateState && response.data is T) {
        setSuccess(response.data as T);
      }
      return response.data;
    } catch (e, st) {
      if (updateState) setError(e, st);
      rethrow;
    }
  }

  /// Convenience POST request delegating to [apiClient].
  Future<R> post<R>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    R Function(dynamic data)? parser,
    bool updateState = false,
  }) async {
    if (updateState) setLoading();
    try {
      final response = await apiClient.post<R>(
        endpoint,
        body: body,
        query: query,
        headers: headers,
        parser: parser,
      );
      if (updateState && response.data is T) {
        setSuccess(response.data as T);
      }
      return response.data;
    } catch (e, st) {
      if (updateState) setError(e, st);
      rethrow;
    }
  }

  /// Convenience PUT request delegating to [apiClient].
  Future<R> put<R>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    R Function(dynamic data)? parser,
    bool updateState = false,
  }) async {
    if (updateState) setLoading();
    try {
      final response = await apiClient.put<R>(
        endpoint,
        body: body,
        query: query,
        headers: headers,
        parser: parser,
      );
      if (updateState && response.data is T) {
        setSuccess(response.data as T);
      }
      return response.data;
    } catch (e, st) {
      if (updateState) setError(e, st);
      rethrow;
    }
  }

  /// Convenience PATCH request delegating to [apiClient].
  Future<R> patch<R>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    R Function(dynamic data)? parser,
    bool updateState = false,
  }) async {
    if (updateState) setLoading();
    try {
      final response = await apiClient.patch<R>(
        endpoint,
        body: body,
        query: query,
        headers: headers,
        parser: parser,
      );
      if (updateState && response.data is T) {
        setSuccess(response.data as T);
      }
      return response.data;
    } catch (e, st) {
      if (updateState) setError(e, st);
      rethrow;
    }
  }

  /// Convenience DELETE request delegating to [apiClient].
  Future<R> delete<R>(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    R Function(dynamic data)? parser,
    bool updateState = false,
  }) async {
    if (updateState) setLoading();
    try {
      final response = await apiClient.delete<R>(
        endpoint,
        body: body,
        query: query,
        headers: headers,
        parser: parser,
      );
      if (updateState && response.data is T) {
        setSuccess(response.data as T);
      }
      return response.data;
    } catch (e, st) {
      if (updateState) setError(e, st);
      rethrow;
    }
  }
}
