import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/models/notificacao/notificacao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router/router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;

  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF017DFE),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.only(top: 37, bottom: 40),
              margin: const EdgeInsets.only(bottom: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "Perfil",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  Positioned(
                    right: 10, // Mantém o ícone no canto direito
                    child: IconButton(
                      onPressed: () async {
                        await supabase.auth.signOut();
                        setLoggedIn(false); // Desativa o GoRouter
                        GoRouter.of(context).go('/enter'); // Volta para a tela inicial
                      },
                      icon: Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20),
                  width: 111,
                  height: 111,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 80,
                  ),
                ),
                SizedBox(
                  width: 50,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Max Augusto",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("47 9976-9152"),
                    Text(currentEmail.toString()),
                    Stack(
                      children: [
                        Opacity(
                          opacity: 0.05,
                          child: Container(
                              width: 70, height: 25, color: Colors.green),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            "Boa Vista",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
            SizedBox(height: 70,),
            Text("Serviços"),
            Container(
              height: 110,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Opacity(
                              opacity: 0.05,
                              child: Container(
                                  width: 100, height: 100, color: Colors.green),
                            ),
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Aula Básica",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  Text("fhiwefherfreferifurefuieyrfuierfyre"),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
