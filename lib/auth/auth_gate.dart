import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:servblu/screens/login_signup/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/home_page/home_screen.dart';
import '../widgets/tool_loading.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context,snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: ToolLoadingIndicator(color: Colors.blue, size: 45),),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if(session != null) {
          return HomePageContent();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
