import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/screens/notification_page/notification_screen.dart';
import 'package:servblu/splash_screen.dart';

import '../layout/layout_scaffold.dart';
import '../screens/home_page/home_screen.dart';
import '../screens/login_signup/enter_screen.dart';
import '../screens/profile_page/profile_screen.dart';
import '../screens/schedule_page/schedule_screen.dart';
import '../screens/service_page/service_screen.dart';

// Chave global do navegador
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Estado de login controlado globalmente
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

// Método para atualizar o estado de login
void setLoggedIn(bool status) {
  isLoggedIn.value = status;
}

// Definição do GoRouter
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.splashScreen,
  refreshListenable: isLoggedIn,
  redirect: (context, state) {
    // Não redirecionamos se estiver indo para splash ou enter
    final isSplashOrEnter = state.uri.path == Routes.splashScreen ||
        state.uri.path == Routes.enterPage;

    if (isSplashOrEnter) {
      return null;
    }

    // Se não estiver logado e tentar acessar outra tela, redireciona para enter
    if (!isLoggedIn.value) {
      return Routes.enterPage;
    }

    return null;
  },
  routes: [
    // Rotas que não usam o shell de navegação (sem barra inferior)
    GoRoute(
      path: Routes.splashScreen,
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: Routes.enterPage,
      builder: (context, state) => EnterScreen(),
    ),

    // Rotas que usam o shell de navegação (com barra inferior)
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