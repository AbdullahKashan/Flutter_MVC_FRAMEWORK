## 1.0.0

- Initial release of `flutter_mvc`.
- Clean MVC architectural layering separating Controllers, Repositories, REST Client, and Views.
- Full `ApiClient` implementation supporting GET, POST, PUT, PATCH, DELETE, and Multipart uploads.
- Reactive `RequestState<T>` (Idle, Loading, Success, Error) with pattern-matching support.
- `MVCController` with lifecycle hooks (`onInit`, `onReady`, `onDispose`) and asynchronous execution helpers.
- `BaseRepository` and `MVCRepository` CRUD abstractions with automated JSON parsing.
- Token management with automatic `Authorization: Bearer` headers and 401 refresh token mutex queue.
- Pluggable storage abstraction (`Storage`, `SecureStorage`, and `MemoryStorage`).
- Built-in lightweight dependency injection (`ServiceLocator`).
- Reusable UI widgets: `MVCView`, `MVCBuilder`, `LoadingView`, and `ErrorView`.
- Infinite scrolling and pagination with `PaginationController` and `PaginatedResponse`.
- Complete unit and widget test suite with 100% pass rate.
- Ready-to-run example application.
