import 'package:flutter/material.dart';

/// Common frame for the auth screens: centered, width-capped, scrollable, so
/// each one reads the same on a phone and on a desktop window.
class AuthPage extends StatelessWidget {
  final String title;
  final Widget child;

  /// Replaces the default back button (e.g. to also cancel a flow).
  final Widget? leading;
  final List<Widget>? actions;

  const AuthPage({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
