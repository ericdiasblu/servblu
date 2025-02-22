import 'package:flutter/material.dart';
import 'package:servblu/screens/login_signup/login_screen.dart';
import 'package:servblu/screens/login_signup/signup_screen.dart';

class EnterScreen extends StatelessWidget {
  const EnterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              top: 46, bottom: 19, left: 21, right: 21),
                          height: 347,
                          width: double.infinity,
                          child: Image(
                            image: AssetImage(
                              'assets/inicial_image.png',
                            ),
                            fit: BoxFit.fill,
                          )),
                      Container(
                        margin: const EdgeInsets.only(
                            bottom: 14, left: 159, right: 159),
                        width: double.infinity,
                        child: Text(
                          "Olá",
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                            bottom: 54, left: 53, right: 53),
                        width: double.infinity,
                        child: Text(
                          "Seja bem-vindo ao ServBlu! Conecte-se a serviços de qualidade em Blumenau.",
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                            bottom: 24,
                            left: 83,
                            right: 83), // Adiciona margens
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF017DFE),
                            // Cor de fundo do botão
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20), // Arredondar bordas
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            // Remove a elevação padrão
                            minimumSize: Size(double.infinity,
                                0), // Para garantir que o botão ocupe toda a largura
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Entrar",
                            style: TextStyle(
                              color: Color(0xFFFFFFFF), // Cor do texto
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center, // Centraliza o texto
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        // Para ocupar toda a largura disponível
                        margin: const EdgeInsets.only(
                            bottom: 191, left: 83, right: 83),
                        // Adiciona margens
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            // Cor de fundo do botão
                            side:
                                BorderSide(color: Color(0xFF017DFE), width: 2),
                            // Bordas do botão
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20), // Arredondar bordas
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0, // Remove a elevação padrão
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Inscrever-se",
                            style: TextStyle(
                              color: Color(0xFF017DFE),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center, // Centraliza o texto
                          ),
                        ),
                      ),
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
