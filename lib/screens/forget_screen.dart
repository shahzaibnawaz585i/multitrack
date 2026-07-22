import 'package:flutter/material.dart';



import '../constants/app_theme.dart';

import 'login_screen.dart';



class ForgetScreen extends StatelessWidget {

  const ForgetScreen({super.key});



  static const Color _accentColor = Color(0xFFF43A6B);



  @override

  Widget build(BuildContext context) {

    return PreLoginThemeScope(

      builder: (lightContext) => Scaffold(

        backgroundColor: lightContext.appBackground,

        body: Column(

          children: [

            const SizedBox(height: 123),

            SizedBox(

              height: 400,

              width: double.infinity,

              child: Image.asset('assets/forgeticon.jpeg'),

            ),

            const SizedBox(height: 65),

            SizedBox(

              width: 260,

              height: 50,

              child: ElevatedButton(

                onPressed: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute<void>(

                      builder: (context) => const LoginScreen(),

                    ),

                  );

                },

                style: ElevatedButton.styleFrom(

                  backgroundColor: _accentColor,

                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(

                    horizontal: 40,

                    vertical: 12,

                  ),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                child: const Text(

                  'Go Back',

                  style: TextStyle(fontFamily: 'normalbold.ttf'),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}

