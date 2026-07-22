import 'package:flutter/material.dart';



import '../constants/app_theme.dart';

import 'dashboard_screen.dart';

import 'forget_screen.dart';



class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});



  @override

  State<LoginScreen> createState() => _LoginScreenState();

}



class _LoginScreenState extends State<LoginScreen> {

  static const Color _accentColor = Color(0xFFF43A6B);



  bool _obscurePassword = true;

  String selectedServer = 'Server 1';

  final TextEditingController userId = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();



  final List<String> servers = ['Server 1', 'Server 2', 'Server 3'];



  InputDecoration _inputDecoration(BuildContext lightContext, String label) {

    return InputDecoration(

      labelText: label,

      labelStyle: TextStyle(color: lightContext.appSecondaryText),

      enabledBorder: UnderlineInputBorder(

        borderSide: BorderSide(color: lightContext.appBorder),

      ),

      focusedBorder: const UnderlineInputBorder(

        borderSide: BorderSide(color: _accentColor, width: 3),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return PreLoginThemeScope(

      builder: (lightContext) => Scaffold(

        backgroundColor: lightContext.appBackground,

        body: SingleChildScrollView(

          child: Column(

            children: [

              const SizedBox(height: 90),

              Padding(

                padding: const EdgeInsets.only(left: 40),

                child: Row(

                  children: [

                    SizedBox(

                      height: 75,

                      width: 75,

                      child: Image.asset('assets/loginicon.png'),

                    ),

                    const SizedBox(width: 12),

                    const Text(

                      'multiTrack',

                      style: TextStyle(

                        fontFamily: 'normalbold.ttf',

                        fontSize: 32,

                        color: _accentColor,

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 50),

              Padding(

                padding: const EdgeInsets.all(14),

                child: Column(

                  children: [

                    Container(

                      height: 300,

                      width: double.infinity,

                      decoration: BoxDecoration(

                        color: lightContext.appSurface,

                        borderRadius: BorderRadius.circular(14),

                        boxShadow: [

                          BoxShadow(

                            color: Colors.black.withValues(alpha: 0.2),

                            blurRadius: 2,

                            spreadRadius: 0.3,

                            offset: const Offset(0, 2),

                          ),

                        ],

                      ),

                      child: Padding(

                        padding: const EdgeInsets.all(14),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Text(

                              'Login',

                              style: TextStyle(

                                fontFamily: 'normalbold.ttf',

                                fontSize: 25,

                                color: lightContext.appTextColor,

                              ),

                            ),

                            Form(

                              key: _formKey,

                              child: TextFormField(

                                controller: userId,

                                style: TextStyle(

                                  color: lightContext.appTextColor,

                                ),

                                decoration: _inputDecoration(

                                  lightContext,

                                  'User ID',

                                ),

                              ),

                            ),

                            TextFormField(

                              obscureText: _obscurePassword,

                              style: TextStyle(

                                color: lightContext.appTextColor,

                              ),

                              decoration: _inputDecoration(

                                lightContext,

                                'Password',

                              ).copyWith(

                                suffixIcon: IconButton(

                                  onPressed: () {

                                    setState(() {

                                      _obscurePassword = !_obscurePassword;

                                    });

                                  },

                                  icon: Icon(

                                    _obscurePassword

                                        ? Icons.visibility_off

                                        : Icons.visibility,

                                    color: lightContext.appSecondaryText,

                                  ),

                                ),

                              ),

                            ),

                            DropdownButtonFormField<String>(

                              isExpanded: true,

                              value: selectedServer,

                              dropdownColor: lightContext.appSurface,

                              style: TextStyle(

                                color: lightContext.appTextColor,

                              ),

                              decoration: InputDecoration(

                                filled: true,

                                fillColor: lightContext.appFieldFill,

                                contentPadding: const EdgeInsets.symmetric(

                                  vertical: 16,

                                ),

                                enabledBorder: UnderlineInputBorder(

                                  borderSide: BorderSide(

                                    color: lightContext.appBorder,

                                  ),

                                ),

                                focusedBorder: const UnderlineInputBorder(

                                  borderSide: BorderSide(

                                    color: _accentColor,

                                    width: 3,

                                  ),

                                ),

                              ),

                              icon: const Icon(

                                Icons.arrow_drop_down,

                                color: _accentColor,

                              ),

                              items: servers.map((server) {

                                return DropdownMenuItem<String>(

                                  value: server,

                                  child: Text(server),

                                );

                              }).toList(),

                              onChanged: (value) {

                                setState(() {

                                  selectedServer = value!;

                                });

                              },

                            ),

                            Align(

                              alignment: Alignment.centerRight,

                              child: TextButton(

                                onPressed: () {

                                  Navigator.push(

                                    context,

                                    MaterialPageRoute<void>(

                                      builder: (context) =>

                                          const ForgetScreen(),

                                    ),

                                  );

                                },

                                child: Text(

                                  'Forget Your Password?',

                                  style: TextStyle(

                                    fontSize: 14,

                                    fontFamily: 'normalbold.ttf',

                                    color: lightContext.appTextColor,

                                  ),

                                ),

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                    const SizedBox(height: 15),

                    Align(

                      alignment: Alignment.center,

                      child: SizedBox(

                        width: 150,

                        height: 50,

                        child: ElevatedButton(

                          onPressed: () {

                            if (_formKey.currentState!.validate()) {

                              if (userId.text == 'admin@gmail.com') {

                                Navigator.push(

                                  context,

                                  MaterialPageRoute<void>(

                                    builder: (context) =>

                                        const DashboardScreen(),

                                  ),

                                );

                              } else {

                                ScaffoldMessenger.of(context).showSnackBar(

                                  const SnackBar(

                                    content: Text('Invalid User Id'),

                                  ),

                                );

                              }

                            }

                          },

                          style: ElevatedButton.styleFrom(

                            backgroundColor: _accentColor,

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(10),

                            ),

                          ),

                          child: const Text(

                            'LOG IN',

                            style: TextStyle(fontFamily: 'normalbold.ttf'),

                          ),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

              SizedBox(

                height: 195,

                width: double.infinity,

                child: Image.asset(

                  'assets/loginscreenicons.jpeg',

                  fit: BoxFit.cover,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}

