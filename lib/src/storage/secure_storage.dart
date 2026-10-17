import 'storage.dart';

/// Storage abstraction specifically designed for sensitive credentials like auth tokens.
abstract class SecureStorage implements Storage {
  const SecureStorage();
}

/// In-memory secure storage fallback when platform-specific keychains are not configured.
class DefaultSecureStorage extends MemoryStorage implements SecureStorage {
  DefaultSecureStorage([super.initialData]);
}
