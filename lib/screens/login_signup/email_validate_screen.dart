import 'package:flutter/material.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/login_signup/forgot_password_screen.dart';

class EmailValidateScreen extends StatelessWidget {
  const EmailValidateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Color(0xFFFFFFFF),
                  width: double.infinity,
                  height: double.infinity,
                  child: SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                            top: 124, bottom: 26, left: 38, right: 171),
                        width: double.infinity,
                        child: Text(
                          "Insira o email da sua conta",
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IntrinsicHeight(
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 25, left: 40, right: 267),
                          width: double.infinity,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Color(0xFF017DFE),
                                    height: 3,
                                    width: double.infinity,
                                  ),
                                ),
                                SizedBox(width: 5,),
                                Container(
                                  color: Color(0xFF017DFE),
                                  width: 13,
                                  height: 3,
                                ),
                              ]),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36), // Adicionando padding global
                        child: Column(
                          children: [
                            InputField(
                              icon: Icons.email,
                              hintText: "Email",
                              controller: null, // Coloque aqui o controller se necessário
                            ),
                            const SizedBox(height: 10),
                            BuildButton(
                              textButton: "Valide seu Email",
                              onPressed: () {
                                // Aqui você pode adicionar a lógica que deseja executar
                                print("Botão 'Valide seu Email' pressionado!");
                                // Você pode adicionar lógica para validar o email aqui
                              },
                              screenRoute: () => ForgotPasswordScreen(), // Passando a função que retorna a tela
                            ),
                          ],
                        ),
                      ),


                      SizedBox(height: 40,),

                      Container(
                          margin: const EdgeInsets.only(
                              bottom: 38, left: 8, right: 8),
                          height: 376,
                          width: double.infinity,
                          child: Image(
                              image: AssetImage(
                                  "assets/forgot_password_image.png")))
                    ],
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
