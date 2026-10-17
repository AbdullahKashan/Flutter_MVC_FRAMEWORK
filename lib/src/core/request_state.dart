import 'package:flutter/foundation.dart';

/// Represents the reactive state of an asynchronous operation or data request.
@immutable
sealed class RequestState<T> {
  const RequestState();

  /// Creates an idle state.
  const factory RequestState.idle() = IdleState<T>;

  /// Creates a loading state, optionally with a progress indicator or message.
  const factory RequestState.loading({String? message, double? progress}) =
      LoadingState<T>;

  /// Creates a success state containing [data].
  const factory RequestState.success(T data) = SuccessState<T>;

  /// Creates an error state containing [error] and optional [stackTrace].
  const factory RequestState.error(dynamic error, [StackTrace? stackTrace]) =
      ErrorState<T>;

  /// Returns true if this state is [IdleState].
  bool get isIdle => this is IdleState<T>;

  /// Returns true if this state is [LoadingState].
  bool get isLoading => this is LoadingState<T>;

  /// Returns true if this state is [SuccessState].
  bool get isSuccess => this is SuccessState<T>;

  /// Returns true if this state is [ErrorState].
  bool get isError => this is ErrorState<T>;

  /// Returns the data if in [SuccessState], otherwise null.
  T? get dataOrNull => switch (this) {
        SuccessState<T>(data: final d) => d,
        _ => null,
      };

  /// Returns the error if in [ErrorState], otherwise null.
  dynamic get errorOrNull => switch (this) {
        ErrorState<T>(error: final err) => err,
        _ => null,
      };

  /// Returns the loading message if in [LoadingState], otherwise null.
  String? get messageOrNull => switch (this) {
        LoadingState<T>(message: final m) => m,
        _ => null,
      };

  /// Returns the progress fraction if in [LoadingState], otherwise null.
  double? get progressOrNull => switch (this) {
        LoadingState<T>(progress: final p) => p,
        _ => null,
      };

  /// Matches the state and executes the corresponding callback.
  R when<R>({
    required R Function() idle,
    required R Function(String? message, double? progress) loading,
    required R Function(T data) success,
    required R Function(dynamic error, StackTrace? stackTrace) error,
  }) {
    return switch (this) {
      IdleState<T>() => idle(),
      LoadingState<T>(message: final m, progress: final p) => loading(m, p),
      SuccessState<T>(data: final d) => success(d),
      ErrorState<T>(error: final err, stackTrace: final st) => error(err, st),
    };
  }

  /// Matches the state and executes the matching callback, or falls back to [orElse].
  R maybeWhen<R>({
    R Function()? idle,
    R Function(String? message, double? progress)? loading,
    R Function(T data)? success,
    R Function(dynamic error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      IdleState<T>() => idle != null ? idle() : orElse(),
      LoadingState<T>(message: final m, progress: final p) =>
        loading != null ? loading(m, p) : orElse(),
      SuccessState<T>(data: final d) => success != null ? success(d) : orElse(),
      ErrorState<T>(error: final err, stackTrace: final st) =>
        error != null ? error(err, st) : orElse(),
    };
  }

  /// Transforms the state using state mapper functions.
  R map<R>({
    required R Function(IdleState<T> state) idle,
    required R Function(LoadingState<T> state) loading,
    required R Function(SuccessState<T> state) success,
    required R Function(ErrorState<T> state) error,
  }) {
    return switch (this) {
      IdleState<T> state => idle(state),
      LoadingState<T> state => loading(state),
      SuccessState<T> state => success(state),
      ErrorState<T> state => error(state),
    };
  }

  /// Transforms the state or falls back to [orElse].
  R maybeMap<R>({
    R Function(IdleState<T> state)? idle,
    R Function(LoadingState<T> state)? loading,
    R Function(SuccessState<T> state)? success,
    R Function(ErrorState<T> state)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      IdleState<T> state => idle != null ? idle(state) : orElse(),
      LoadingState<T> state => loading != null ? loading(state) : orElse(),
      SuccessState<T> state => success != null ? success(state) : orElse(),
      ErrorState<T> state => error != null ? error(state) : orElse(),
    };
  }
}

/// The initial or reset state of an operation before any request has started.
class IdleState<T> extends RequestState<T> {
  const IdleState();

  @override
  String toString() => 'RequestState<$T>.idle()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is IdleState<T>);

  @override
  int get hashCode => T.hashCode ^ 1;
}

/// The state while an asynchronous request is in progress.
class LoadingState<T> extends RequestState<T> {
  final String? message;
  final double? progress;

  const LoadingState({this.message, this.progress});

  @override
  String toString() =>
      'RequestState<$T>.loading(message: $message, progress: $progress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoadingState<T> &&
          other.message == message &&
          other.progress == progress);

  @override
  int get hashCode => Object.hash(T, message, progress);
}

/// The state when a request completes successfully with [data].
class SuccessState<T> extends RequestState<T> {
  final T data;

  const SuccessState(this.data);

  @override
  String toString() => 'RequestState<$T>.success(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuccessState<T> &&
          (identical(other.data, data) || other.data == data));

  @override
  int get hashCode => Object.hash(T, data);
}

/// The state when a request encounters an error.
class ErrorState<T> extends RequestState<T> {
  final dynamic error;
  final StackTrace? stackTrace;

  const ErrorState(this.error, [this.stackTrace]);

  @override
  String toString() => 'RequestState<$T>.error(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorState<T> && other.error == error);

  @override
  int get hashCode => Object.hash(T, error);
}
