import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../layout/layout_scaffold.dart';
import '../../router/routes.dart';
import '../notification_page/notification_screen.dart';
import '../profile_page/profile_screen.dart';
import '../schedule_page/schedule_screen.dart';
import '../service_page/service_screen.dart';
import 'home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    router = GoRouter(
      initialLocation: Routes.homePage,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => LayoutScaffold(
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: Routes.homePage, builder: (_, __) => const HomePageContent())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.schedulePage, builder: (_, __) => ScheduleScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.servicePage, builder: (_, __) => ServiceScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.notificationPage, builder: (_, __) => NotificationScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.profilePage, builder: (_, __) => ProfileScreen())]),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
