// // import 'package:flutter/material.dart';
// // import 'package:multitrack/login_screen.dart';
// // import 'package:multitrack/time_screen.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //         debugShowCheckedModeBanner: false,
// //       home:
// //       TimeScreen()
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:multitrack/screens/time_screen.dart';
// void main() {
//   runApp(const MyApp());
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home:
//       TimeScreen() ,
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'constants/app_fonts.dart';
import 'screens/time_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultiTrackApp());
}

class MultiTrackApp extends StatelessWidget {
  const MultiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: AppFonts.regular,
      ),
      home: const TimeScreen(),
    );
  }
}
