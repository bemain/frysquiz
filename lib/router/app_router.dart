import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/user_model.dart';
import '../features/admin/forms/admin_form_detail_screen.dart';
import '../features/admin/forms/admin_forms_screen.dart';
import '../features/admin/forms/create_form_screen.dart';
import '../features/admin/groups/admin_group_detail_screen.dart';
import '../features/admin/groups/admin_groups_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/overview_screen.dart';
import '../features/admin/users/admin_users_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/public/public_form_screen.dart';
import '../features/user/form_fill_screen.dart';
import '../features/user/groups_screen.dart';
import '../features/user/home_screen.dart';
import '../features/user/profile_screen.dart';
import '../features/user/user_shell.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = authNotifier.currentUser;
      final loc = state.matchedLocation;

      if (loc.startsWith('/fill/')) return null;

      if (user == null) {
        return loc == '/login' ? null : '/login';
      }

      if (loc == '/login') {
        return user.role == UserRole.user ? '/home' : '/admin/overview';
      }

      if (user.role == UserRole.user && loc.startsWith('/admin')) {
        return '/home';
      }

      if (loc.startsWith('/admin/users') && user.role != UserRole.superadmin) {
        return '/admin/overview';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/fill/:formId',
        builder: (context, state) =>
            PublicFormScreen(formId: state.pathParameters['formId']!),
      ),
      ShellRoute(
        builder: (context, state, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/form/:id',
            builder: (context, state) =>
                FormFillScreen(formId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (_, _) => '/admin/overview',
          ),
          GoRoute(
            path: '/admin/overview',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/admin/groups',
            builder: (context, state) => const AdminGroupsScreen(),
          ),
          GoRoute(
            path: '/admin/groups/:id',
            builder: (context, state) =>
                AdminGroupDetailScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/forms',
            builder: (context, state) => const AdminFormsScreen(),
          ),
          GoRoute(
            path: '/admin/forms/create',
            builder: (context, state) => const CreateFormScreen(),
          ),
          GoRoute(
            path: '/admin/forms/:id',
            builder: (context, state) =>
                AdminFormDetailScreen(formId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
        ],
      ),
    ],
  );

  return router;
});
