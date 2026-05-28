/// SRIBEESonline - Navigation Helpers
///
/// Provides a smooth Fade + Slide transition via [FadePageRoute] and named-
/// route push helpers used across the onboarding flow.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Fade transition page route
// ---------------------------------------------------------------------------

/// A [PageRouteBuilder] that applies a combined Fade + subtle Slide-up
/// transition.  Duration is configurable (defaults to 400 ms).
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({
    required this.page,
    Duration duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeInOut);

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

// ---------------------------------------------------------------------------
// Push helpers
// ---------------------------------------------------------------------------

/// Navigate forward with fade transition.
Future<T?> pushFade<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(FadePageRoute(page: page));
}

/// Replace the current route with a fade transition.
Future<T?> pushReplacementFade<T>(BuildContext context, Widget page) {
  return Navigator.of(context)
      .pushReplacement(FadePageRoute<T>(page: page));
}

/// Clear the entire navigation stack and land on [page].
Future<T?> pushAndClearFade<T>(BuildContext context, Widget page) {
  return Navigator.of(context).pushAndRemoveUntil(
    FadePageRoute<T>(page: page),
    (_) => false,
  );
}
