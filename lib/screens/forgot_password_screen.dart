import 'package:flutter/material.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/login_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
                            margin: const EdgeInsets.only(top: 105,
                                bottom: 45,
                                left: 42,
                                right: 74),
                            width: double.infinity,
                            child: Text(
                              "Insira a nova senha para sua conta",
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
                          Padding(padding: const EdgeInsets.symmetric(
                              horizontal: 36), // Adicionando padding global
                            child: Column(children: [
                              InputField(
                                  icon: Icons.lock, hintText: "New Password"),
                              InputField(icon: Icons.lock,
                                  hintText: "Confirm New Password"),
                              SizedBox(height: 20,),
                              BuildButton(textButton: "Atualize sua senha",screenRoute: LoginScreen(),)
                            ],),),

                          SizedBox(height: 30,),
                        ],
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
