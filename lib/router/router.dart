import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/screens/notification_page/notification_screen.dart';

import '../layout/layout_scaffold.dart';
import '../screens/home_page/home_struture.dart';
import '../screens/profile_page/profile_screen.dart';
import '../screens/schedule_page/schedule_screen.dart';
import '../screens/service_page/service_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.homePage,
  routes: [
    StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => LayoutScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.homePage,
                builder: (context, state) => HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.schedulePage,
                builder: (context, state) => ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.servicePage,
                builder: (context,state) => ServiceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notificationPage,
                builder: (context,state) => NotificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profilePage,
                builder: (context,state) => ProfileScreen(),
              ),
            ],
          ),
        ]),
  ],
);