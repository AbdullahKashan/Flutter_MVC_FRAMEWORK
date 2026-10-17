import 'package:flutter/widgets.dart';
import '../dependency/service_locator.dart';
import 'mvc_controller.dart';

/// Base class for stateful views wired to an [MVCController].
///
/// Automatically manages controller initialization, post-frame [MVCController.onReady],
/// and lifecycle disposal.
abstract class MVCView<C extends MVCController> extends StatefulWidget {
  final C? controller;
  final bool autoDispose;

  const MVCView({
    super.key,
    this.controller,
    this.autoDispose = true,
  });

  /// Factory method to instantiate the controller if not passed via constructor.
  /// Defaults to resolving from [ServiceLocator] or throwing if not found.
  C createController(BuildContext context) {
    if (controller != null) return controller!;
    if (ServiceLocator().isRegistered<C>()) {
      return ServiceLocator().get<C>();
    }
    throw FlutterError(
      'Controller of type $C was not provided to $runtimeType and is not registered in ServiceLocator. '
      'Either pass controller via constructor or override createController().',
    );
  }

  @override
  MVCViewState<C, MVCView<C>> createState();
}

/// Companion State class for [MVCView].
abstract class MVCViewState<C extends MVCController, W extends MVCView<C>>
    extends State<W> {
  late final C controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
      _ownsController = false;
    } else {
      controller = widget.createController(context);
      _ownsController = widget.autoDispose;
    }

    if (!controller.isInitialized) {
      controller.onInit();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !controller.isDisposed) {
        controller.onReady();
      }
    });
  }

  @override
  void dispose() {
    if (_ownsController && !controller.isDisposed) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildView(context, controller);

  /// Builds the view hierarchy given the resolved [controller].
  Widget buildView(BuildContext context, C controller);
}

/// A lightweight, stateless view component that resolves its controller
/// directly from [ServiceLocator] or an external property.
abstract class MVCStatelessView<C extends MVCController> extends StatelessWidget {
  final C? controller;

  const MVCStatelessView({super.key, this.controller});

  /// Resolves the controller from constructor or [ServiceLocator].
  C resolveController() {
    if (controller != null) return controller!;
    return ServiceLocator().get<C>();
  }

  @override
  Widget build(BuildContext context) => buildView(context, resolveController());

  /// Builds the view using the resolved [controller].
  Widget buildView(BuildContext context, C controller);
}
