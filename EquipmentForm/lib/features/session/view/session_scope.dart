import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ensures descendants share the same provider container without introducing
/// nested scopes. Tests can inject a specific [ProviderContainer] while
/// production code reuses the ancestor container.
class SessionScope extends StatelessWidget {
  const SessionScope({
    super.key,
    required this.child,
    this.container,
  });

  final Widget child;
  final ProviderContainer? container;

  @override
  Widget build(BuildContext context) {
    final root = container ?? ProviderScope.containerOf(context, listen: false);
    return UncontrolledProviderScope(
      container: root,
      child: child,
    );
  }
}
