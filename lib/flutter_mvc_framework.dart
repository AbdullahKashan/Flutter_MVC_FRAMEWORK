/// A modular, robust, and batteries-included Model-View-Controller framework
/// for Flutter applications with integrated REST networking, authentication,
/// reactive state management, and repository pattern support.
library;

// Core
export 'src/mvc.dart';
export 'src/core/mvc_controller.dart';
export 'src/core/mvc_model.dart';
export 'src/core/mvc_view.dart';
export 'src/core/request_state.dart';
export 'src/core/mvc_exception.dart';

// Network
export 'src/network/api_client.dart';
export 'src/network/api_config.dart';
export 'src/network/api_response.dart';
export 'src/network/api_exception.dart';
export 'src/network/http_method.dart';
export 'src/network/interceptor.dart';
export 'src/network/multipart_request.dart';

// Auth
export 'src/auth/auth_manager.dart';
export 'src/auth/token_manager.dart';
export 'src/auth/auth_interceptor.dart';

// Repository
export 'src/repository/base_repository.dart';

// Storage
export 'src/storage/storage.dart';
export 'src/storage/secure_storage.dart';

// Pagination
export 'src/pagination/pagination_controller.dart';

// Dependency Injection
export 'src/dependency/service_locator.dart';

// Widgets
export 'src/widgets/mvc_builder.dart';
export 'src/widgets/loading_view.dart';
export 'src/widgets/error_view.dart';
