import 'package:flutter/material.dart';

class SlideFromRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideFromRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // RIGHT TO LEFT slide: start from RIGHT (1.0) → end at CENTER (0.0)
            // When returning, this automatically reverses to LEFT TO RIGHT
            
            const begin = Offset(1.0, 0.0);   // Start from RIGHT (off-screen right)
            const end = Offset.zero;          // End at center (on-screen)
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class SlideFromLeftRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideFromLeftRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // LEFT TO RIGHT slide: start from LEFT (-1.0) → end at CENTER (0.0)
            // When returning, this automatically reverses to RIGHT TO LEFT
            const begin = Offset(-1.0, 0.0);  // Start from LEFT (off-screen left)
            const end = Offset.zero;          // End at center (on-screen)
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from bottom to top (for settings navigation)
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class SlideDownRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideDownRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from top to bottom (for back from settings)
            const begin = Offset(0.0, -1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class SlideCurrentOutRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideCurrentOutRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Simple approach: new screen just appears (no animation)
            // The magic happens with the secondaryAnimation on the old screen
            return child;
          },
        );
}