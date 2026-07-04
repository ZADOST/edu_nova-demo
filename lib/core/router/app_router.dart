import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../db/local_auth_db.dart';
import '../theme/app_theme.dart';

// Importing all 7 finalized role-based dashboards
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/dashboard_student/presentation/student_dashboard.dart';
import '../../features/dashboard_teacher/presentation/teacher_dashboard.dart';
import '../../features/dashboard_teacher/presentation/teacher_attendance_screen.dart';
import '../../features/dashboard_teacher/presentation/teacher_grade_entry_screen.dart';
import '../../features/dashboard_student/presentation/student_attendance_scanner_screen.dart';
import '../../features/management_admin/presentation/assistant_dashboard.dart';
import '../../features/management_admin/presentation/principal_dashboard.dart';
import '../../features/management_admin/presentation/principal_student_id_cards_screen.dart';
import '../../features/dashboard_teacher/presentation/teacher_student_id_scan_screen.dart';
import '../../features/dashboard_teacher/presentation/teacher_student_qr_scanner_screen.dart';
import '../../features/management_finance/presentation/accounting_dashboard.dart';
import '../../features/management_hr/presentation/hr_dashboard.dart';
import '../../features/portal_alumni/presentation/alumni_dashboard.dart';
import '../data/student_id_card_repository.dart';
import '../screens/splash_screen.dart';
import '../screens/parent_dashboard.dart';
import '../screens/settings_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  final LocalAuthDb authDb;

  AppRouter(this.authDb);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(),
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authDb.isLoggedIn;
      final bool loggingIn = state.matchedLocation == '/login';
      final bool isSplash = state.matchedLocation == '/splash';

      // Allow splash to show before any redirection
      if (isSplash) {
        return null;
      }

      // 1. Force unauthenticated users to login
      if (!loggedIn && !loggingIn) {
        return '/login';
      }

      // 2. Redirect authenticated users to their specific role dashboard
      if (loggedIn && loggingIn) {
        final role = authDb.userRole;
        switch (role) {
          case 'student': return '/student';
          case 'teacher': return '/teacher';
          case 'parent': return '/parent';
          case 'assistant_principal': return '/assistant_principal';
          case 'principal': return '/principal';
          case 'accounting': return '/accounting';
          case 'hr': return '/hr';
          case 'alumni': return '/alumni';
          default: return '/login'; 
        }
      }
      return null; 
    },
    // 3. Graceful 404 handling
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
            const SizedBox(height: 16),
            const Text('404 - Route Not Found', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => context.go('/splash'), child: const Text('Return Home')),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/student/attendance',
        builder: (context, state) => const StudentAttendanceScannerScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/teacher/attendance',
        builder: (context, state) => const TeacherAttendanceScreen(),
      ),
      GoRoute(
        path: '/teacher/grade-entry',
        builder: (context, state) => TeacherGradeEntryScreen(
          initialCourse: state.queryParameters['course'] ?? 'Advanced Java OOP',
        ),
      ),
      GoRoute(
        path: '/teacher/student-scan',
        builder: (context, state) {
          final studentId = state.queryParameters['id'];
          final student = StudentIdCardRepository.findById(studentId ?? '') ?? StudentIdCardRepository.sampleCards.first;
          return TeacherStudentIdScanScreen(student: student);
        },
      ),
      GoRoute(
        path: '/teacher/student-qr-scanner',
        builder: (context, state) => const TeacherStudentQrScannerScreen(),
      ),
      GoRoute(
        path: '/assistant_principal',
        builder: (context, state) => const PrincipalAssistantDashboard(),
      ),
      GoRoute(
        path: '/principal',
        builder: (context, state) => const PrincipalDashboard(),
      ),
      GoRoute(
        path: '/principal/student-id-cards',
        builder: (context, state) => const PrincipalStudentIdCardsScreen(),
      ),
      GoRoute(
        path: '/accounting',
        builder: (context, state) => const AccountingDashboard(),
      ),
      GoRoute(
        path: '/hr',
        builder: (context, state) => const HRDashboard(),
      ),
      GoRoute(
        path: '/alumni',
        builder: (context, state) => const AlumniDashboard(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentDashboard(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/timetable',
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {}