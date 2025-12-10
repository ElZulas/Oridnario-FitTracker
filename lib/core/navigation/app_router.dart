import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/activities/presentation/pages/activity_form_page.dart';
import '../../features/activities/presentation/pages/activities_calendar_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/dashboard/presentation/pages/statistics_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../core/constants/app_constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/activity/form',
        name: 'activity-form',
        builder: (context, state) {
          final activityId = state.uri.queryParameters['id'];
          return ActivityFormPage(activityId: activityId);
        },
      ),
      GoRoute(
        path: '/activities/calendar',
        name: 'activities-calendar',
        builder: (context, state) => const ActivitiesCalendarPage(),
      ),
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
    // Deep linking configuration
    redirect: (context, state) {
      // La lógica de redirección se manejará en SplashPage
      return null;
    },
  );

  // Deep link handler
  static void handleDeepLink(String link) {
    if (link.startsWith('${AppConstants.deepLinkScheme}://')) {
      final uri = Uri.parse(link);
      if (uri.path == AppConstants.deepLinkActivityPath) {
        final activityId = uri.queryParameters['id'];
        router.go('/activity/form?id=$activityId');
      }
    }
  }
}


