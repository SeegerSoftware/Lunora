import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/child_profile/presentation/child_profile_setup_screen.dart';
import '../features/child_profile/presentation/providers/child_profile_providers.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/parent/presentation/parent_area_screen.dart';
import '../features/stories/presentation/story_history_screen.dart';
import '../features/stories/presentation/story_reader_screen.dart';
import '../features/subscription/presentation/subscription_screen.dart';
import 'router_refresh.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/signin',
        builder: (BuildContext context, GoRouterState state) {
          return const SignInScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) {
          return const SignUpScreen();
        },
      ),
      GoRoute(
        path: '/setup-child',
        builder: (BuildContext context, GoRouterState state) {
          return const ChildProfileSetupScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/story',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.uri.queryParameters['id'];
          return StoryReaderScreen(storyId: id);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (BuildContext context, GoRouterState state) {
          return const StoryHistoryScreen();
        },
      ),
      GoRoute(
        path: '/parent',
        builder: (BuildContext context, GoRouterState state) {
          return const ParentAreaScreen();
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (BuildContext context, GoRouterState state) {
          return const SubscriptionScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final user = ref.read(authSessionProvider);
      final child = ref.read(childProfileProvider);
      final loc = state.matchedLocation;

      if (user == null) {
        const publicRoutes = <String>{'/welcome', '/signin', '/signup'};
        if (publicRoutes.contains(loc)) return null;
        return '/welcome';
      }

      if (child == null) {
        if (loc == '/setup-child') return null;
        return '/setup-child';
      }

      // Ne pas inclure `/setup-child` ici : le parent doit pouvoir rouvrir le
      // formulaire pour modifier le profil sans être renvoyé vers `/home`.
      const gateRoutes = <String>{'/welcome', '/signin', '/signup'};
      if (gateRoutes.contains(loc)) return '/home';

      return null;
    },
  );
});
