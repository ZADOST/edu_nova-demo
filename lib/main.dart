import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/db/local_auth_db.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force portrait mode for a consistent UI layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Initialize the Local Authentication Database
  final localAuthDb = await LocalAuthDb.init();

  // 2. Instantiate the AppRouter with the database instance
  final appRouter = AppRouter(localAuthDb);

  // 3. Pass the specific router instance to the root app
  runApp(EduNovaApp(appRouter: appRouter));
}

class EduNovaApp extends StatelessWidget {
  final AppRouter appRouter;

  const EduNovaApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Edu Nova',
      debugShowCheckedModeBanner: false, // Removes the debug banner for a clean demo
      theme: AppTheme.darkTheme, // Uses your pre-configured dark theme
      routerConfig: appRouter.router, // Correctly accesses the instance member
    );
  }
}