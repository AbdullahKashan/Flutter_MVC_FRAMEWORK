import '../core/mvc_exception.dart';

enum _ServiceType { instance, lazySingleton, factory }

class _ServiceEntry<T> {
  final _ServiceType type;
  T? instance;
  final T Function()? factory;

  _ServiceEntry.instance(this.instance)
      : type = _ServiceType.instance,
        factory = null;

  _ServiceEntry.lazySingleton(this.factory)
      : type = _ServiceType.lazySingleton,
        instance = null;

  _ServiceEntry.factory(this.factory)
      : type = _ServiceType.factory,
        instance = null;

  T resolve() {
    switch (type) {
      case _ServiceType.instance:
        return instance!;
      case _ServiceType.lazySingleton:
        instance ??= factory!();
        return instance!;
      case _ServiceType.factory:
        return factory!();
    }
  }
}

/// A lightweight, type-safe dependency injection service locator.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  /// Global singleton instance.
  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  final Map<Type, _ServiceEntry<dynamic>> _registry = {};

  /// Registers an existing [instance] of type [T].
  void register<T>(T instance) {
    _registry[T] = _ServiceEntry<T>.instance(instance);
  }

  /// Registers a lazy singleton factory of type [T].
  /// The instance will be instantiated once upon first request.
  void registerLazySingleton<T>(T Function() factory) {
    _registry[T] = _ServiceEntry<T>.lazySingleton(factory);
  }

  /// Registers a factory of type [T] which is invoked on every retrieval.
  void registerFactory<T>(T Function() factory) {
    _registry[T] = _ServiceEntry<T>.factory(factory);
  }

  /// Retrieves an instance of type [T].
  T get<T>() {
    final entry = _registry[T];
    if (entry == null) {
      throw DependencyNotFoundException(T);
    }
    return entry.resolve() as T;
  }

  /// Callable shorthand for [get].
  T call<T>() => get<T>();

  /// Checks if a service of type [T] is registered.
  bool isRegistered<T>() => _registry.containsKey(T);

  /// Unregisters the service of type [T].
  void unregister<T>() {
    _registry.remove(T);
  }

  /// Clears all registered services.
  void reset() {
    _registry.clear();
  }
}
