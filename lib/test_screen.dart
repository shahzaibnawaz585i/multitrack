import 'package:flutter/material.dart';
 class TestScreen extends StatefulWidget {
   const TestScreen({super.key});

   @override
   State<TestScreen> createState() => _TestScreenState();
 }

 class _TestScreenState extends State<TestScreen> {
   @override
   Widget build(BuildContext context) {
     return Scaffold(
body: // Row(
       //   children: [
       //     Column(
       //       children: [
       //         SizedBox(
       //           height: 10,
       //         ),
       //         Text(name,style: TextStyle(
       //             fontFamily: 'loginfonts.ttf',fontSize: 16
       //         ),) ,
       //
       //       ],
       //     ),
       //     Row(
       //       children: [
       //         Column(
       //           children: [
       //             Padding(
       //               padding: const EdgeInsets.only(right: 20),
       //               child:
       //               Positioned(
       //                 top: 5,
       //                 child: Stack(
       //                   alignment: Alignment.center,
       //                   children: [
       //                     // Shadow/Glow effect
       //                     Container(
       //                       height: 15,
       //                       width: 15,
       //                       decoration: BoxDecoration(
       //                         shape: BoxShape.circle,
       //                         color: color.withOpacity(0.2),
       //                       ),
       //                     ),
       //
       //                     // Inner Colored Circle
       //                     Container(
       //                       height: 10,
       //                       width: 10,
       //                       decoration: BoxDecoration(
       //                         shape: BoxShape.circle,
       //                         gradient: LinearGradient(
       //                           begin: Alignment.topLeft,
       //                           end: Alignment.bottomRight,
       //                           colors: [color.withOpacity(0.8), color],
       //
       //                         ),
       //                       ),
       //                     ),
       //
       //
       //                   ],
       //                 ),
       //               ),
       //
       //             ),
       //
       //             Text('$status')
       //
       //           ],
       //         )
       //       ],
       //     )
       //
       //
       //
       //   ],
       // ),,
     );
   }
 }
