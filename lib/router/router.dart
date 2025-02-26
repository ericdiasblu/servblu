import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/screens/notification_page/notification_screen.dart';

import '../layout/layout_scaffold.dart';
import '../screens/home_page/home_screen.dart';
import '../screens/login_signup/enter_screen.dart';
import '../screens/profile_page/profile_screen.dart';
import '../screens/schedule_page/schedule_screen.dart';
import '../screens/service_page/service_screen.dart';

// Chave global do navegador
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Estado de login controlado globalmente
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

// Método para atualizar o estado de login
void setLoggedIn(bool status) {
  isLoggedIn.value = status;
}

// Definição do GoRouter
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.homePage,
  refreshListenable: isLoggedIn, // Atualiza quando o login muda
  redirect: (context, state) {
    // Se não estiver logado e não estiver na tela inicial, redireciona
    final isGoingToHome = state.uri.path == Routes.homePage;
    if (!isLoggedIn.value && isGoingToHome) {
      return '/enter'; // Redireciona para a tela inicial
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/enter',
      builder: (context, state) => EnterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => LayoutScaffold(
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.homePage,
              builder: (context, state) => HomePageContent(),
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
              builder: (context, state) => ServiceScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.notificationPage,
              builder: (context, state) => NotificationScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profilePage,
              builder: (context, state) => ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
