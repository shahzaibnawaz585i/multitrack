import 'package:flutter/material.dart';
import 'package:multitrack/dashboard_screen.dart';
import 'package:multitrack/forget_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword =true;
  bool isPasswordHidden = true;
  String selectedServer = "Server 1";
  TextEditingController userId=TextEditingController();
  final _formKey=GlobalKey<FormState>();


  final List<String> servers = [
    "Server 1",
    "Server 2",
    "Server 3",
  ];
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
              height:90,
            ),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Row(
                  children: [
                        Container(
                          height: 75,
                          width: 75,
                          child: Image.asset('assets/loginicon.png'),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),

                          ),
                        ),
                    SizedBox(
                      height: 20,
                    ),
                    Text('multiTrack',style: TextStyle(fontFamily: 'normalbold.ttf',fontSize: 32,
                      color:  Color(0xFFF43A6B
                      ),
                    ),)

                  ]
                ),
              ),
              SizedBox(
                height:50,
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 2,
                            spreadRadius: 0.3,
                            offset: Offset(0, 2)
                          )
                        ],

                      ),
                      child:
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 4,
                            ),
                            Text('Login',style: TextStyle(fontFamily: 'normalbold.ttf',fontSize: 25),),
                            Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: userId,

                                decoration: InputDecoration(
                                    label: Text('User ID'),

                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey,
                                            width: 1
                                        )
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(8),bottomLeft: Radius.circular(8)),
                                        borderSide: BorderSide(
                                            color: Color(0xFFEF3868),
                                            width: 3
                                        )
                                    )
                                ),
                              ),
                            ),


                            TextFormField(
                              obscureText: _obscurePassword,                      
                              decoration: InputDecoration(
                                  label: Text('Password'),
                                  suffixIcon: IconButton(onPressed: (){
                                    setState(() {
                                      _obscurePassword=!_obscurePassword;
                                    });
                                  }, icon: Icon(_obscurePassword?Icons.visibility_off:Icons.visibility)),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey,
                                          width: 1
                                      )
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8),bottomRight: Radius.circular(8)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFEF3868),

                                          width: 3
                                      )
                                  )
                              ),
                            ),

                      DropdownButtonFormField<String>(
                        isExpanded: true,
                       value: selectedServer,
                        decoration: InputDecoration(

                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink,
                              width: 3
                            ),
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8),bottomRight: Radius.circular(8)),
                          )
                        ),
                        icon:Icon (Icons.arrow_drop_down,color: Color(0xFFF43A6B),),
                        items:servers.map((servers){
                          return DropdownMenuItem<String>(
                            value: servers,
                              child: Text(servers));
                        }).toList(),
                        onChanged: (value){

                         selectedServer=value!;
                        },
                      ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 137), // thoda adjust if needed
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgetScreen()));
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Forget Your Password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'normalbold.ttf',
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),


                          ],
                        ),
                      )

                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 160),
                      child: SizedBox(
                        width: 150,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if(_formKey.currentState!.validate()){
                              String userid=userId.text;
                              if(userid=="admin@gmail.com"){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>DashboardScreen()));
                              }else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invalid User Id'))
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF43A6B),   // button color
                            foregroundColor: Colors.white,  // text color
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text("LOG IN",style: TextStyle(fontFamily: 'normalbold.ttf'),),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              Container(
                height: 195,
                width: double.infinity,
                child: Image.asset('assets/loginscreenicons.jpeg',
                  fit: BoxFit.cover,
                ),
              )


            ],
          )),
    );
  }
}
