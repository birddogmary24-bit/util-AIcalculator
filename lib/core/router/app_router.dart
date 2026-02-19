import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/calculator/calculator_screen.dart';
import '../../presentation/ai_chat/ai_chat_screen.dart';
import '../../presentation/history/history_screen.dart';
import '../../presentation/common/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalculatorScreen(),
          ),
        ),
        GoRoute(
          path: '/ai',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AiChatScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
      ],
    ),
  ],
);
