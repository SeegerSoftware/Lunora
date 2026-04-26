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
import '../features/stories/presentation/instant_story_screen.dart';
import '../features/stories/presentation/story_bedtime_reader_screen.dart';
import '../features/stories/presentation/story_reader_screen.dart';
import '../features/subscription/presentation/stripe_checkout_screen.dart';
import '../features/subscription/presentation/subscription_screen.dart';
import 'lunora_page_transitions.dart';
import 'router_refresh.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/signin',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/setup-child',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const ChildProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/generate',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const InstantStoryScreen(),
        ),
      ),
      GoRoute(
        path: '/story',
        pageBuilder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return lunoraFadePage(
            key: state.pageKey,
            child: StoryReaderScreen(storyId: id),
          );
        },
      ),
      GoRoute(
        path: '/story/bedtime',
        pageBuilder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return lunoraFadePage(
            key: state.pageKey,
            child: StoryBedtimeReaderScreen(storyId: id),
          );
        },
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const StoryHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/parent',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const ParentAreaScreen(),
        ),
      ),
      GoRoute(
        path: '/subscription',
        pageBuilder: (context, state) => lunoraFadePage(
          key: state.pageKey,
          child: const SubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: '/stripe-checkout',
        pageBuilder: (context, state) {
          final planId = state.uri.queryParameters['planId'] ?? 'plan_elunai';
          return lunoraFadePage(
            key: state.pageKey,
            child: StripeCheckoutScreen(initialPlanId: planId),
          );
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

      const gateRoutes = <String>{'/welcome', '/signin', '/signup'};
      if (gateRoutes.contains(loc)) return '/home';

      return null;
    },
  );
});
