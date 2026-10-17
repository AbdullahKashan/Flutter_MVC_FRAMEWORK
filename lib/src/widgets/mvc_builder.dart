import 'package:flutter/material.dart';
import '../core/mvc_controller.dart';
import '../core/request_state.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// Callback signature for reacting to state changes as side effects (e.g. Snackbars, navigation).
typedef MVCStateListener<T> = void Function(BuildContext context, RequestState<T> state);

/// A reactive widget that listens to an [MVCController] and rebuilds its UI according
/// to the current [RequestState].
class MVCBuilder<C extends MVCController<T>, T> extends StatefulWidget {
  /// The controller instance to observe.
  final C controller;

  /// Main builder providing the raw state. If specified, overrides individual state callbacks.
  final Widget Function(BuildContext context, RequestState<T> state)? builder;

  /// Builder invoked when state is [SuccessState].
  final Widget Function(BuildContext context, T data)? onSuccess;

  /// Builder invoked when state is [LoadingState]. Defaults to [LoadingView].
  final Widget Function(BuildContext context, String? message, double? progress)? onLoading;

  /// Builder invoked when state is [ErrorState]. Defaults to [ErrorView].
  final Widget Function(BuildContext context, dynamic error, StackTrace? stackTrace)? onError;

  /// Builder invoked when state is [IdleState]. Defaults to an empty [SizedBox].
  final Widget Function(BuildContext context)? onIdle;

  /// Optional side-effect listener executed when the controller state changes.
  final MVCStateListener<T>? listener;

  const MVCBuilder({
    super.key,
    required this.controller,
    this.builder,
    this.onSuccess,
    this.onLoading,
    this.onError,
    this.onIdle,
    this.listener,
  }) : assert(
          builder != null || onSuccess != null,
          'Either `builder` or `onSuccess` must be provided to MVCBuilder.',
        );

  @override
  State<MVCBuilder<C, T>> createState() => _MVCBuilderState<C, T>();
}

class _MVCBuilderState<C extends MVCController<T>, T> extends State<MVCBuilder<C, T>> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleStateChange);
  }

  @override
  void didUpdateWidget(covariant MVCBuilder<C, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleStateChange);
      widget.controller.addListener(_handleStateChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      widget.listener?.call(context, widget.controller.state);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;

    if (widget.builder != null) {
      return widget.builder!(context, state);
    }

    return state.when(
      idle: () {
        if (widget.onIdle != null) {
          return widget.onIdle!(context);
        }
        return const SizedBox.shrink();
      },
      loading: (message, progress) {
        if (widget.onLoading != null) {
          return widget.onLoading!(context, message, progress);
        }
        return LoadingView(message: message, progress: progress);
      },
      success: (data) {
        return widget.onSuccess!(context, data);
      },
      error: (error, stackTrace) {
        if (widget.onError != null) {
          return widget.onError!(context, error, stackTrace);
        }
        return ErrorView(error: error);
      },
    );
  }
}
