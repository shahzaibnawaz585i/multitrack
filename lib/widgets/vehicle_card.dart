import 'package:flutter/material.dart';
import '../constants/app_images.dart';
// import '../constants/app_fonts.dart';
import '../models/vehicle_model.dart';
import '../screens/vehicle_detail_screen.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleCard({super.key, required this.vehicle});

  String getLockImage() {
    switch (vehicle.status.toLowerCase()) {
      case "running":
        return AppImages.runningLock;

      case "stopped":
        return AppImages.stopLock;

      case "idle":
      case "idel":
        return AppImages.idleLock;

      case "inactive":
        return AppImages.inactiveLock;

      default:
        return AppImages.inactiveLock;
    }
  }

  String getCarImage() {
    switch (vehicle.status.toLowerCase()) {
      case "running":
        return AppImages.runningCar;

      case "stopped":
        return AppImages.stopCar;

      case "idle":
      case "idel":
        return AppImages.idleCar;

      case "inactive":
        return AppImages.inactiveCar;

      default:
        return AppImages.inactiveCar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(
              name: vehicle.name,
              status: vehicle.status,
              color: vehicle.color,
              speed: vehicle.speed,
              distance: vehicle.distance,
              time: vehicle.time,
              livetime: vehicle.liveTime,
              location: vehicle.location,
              date: vehicle.date,
            ),
          ),
        );
      },

      child: Container(
        height: 160,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Container(
                    height: 30,
                    width: 30,
                    child: Image.asset(getLockImage(), fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Row(
              children: [
                Column(
                  children: [
                    SizedBox(height: 40),
                    Container(
                      height: 50,
                      width: 60,

                      child: Image.asset(getCarImage(), fit: BoxFit.contain),
                    ),
                    SizedBox(height: 5),
                    Text(
                      vehicle.speed,
                      style: TextStyle(fontFamily: 'numberfonts', fontSize: 20),
                    ),
                    Text('kmph', style: TextStyle(fontFamily: 'medium.ttf')),
                  ],
                ),
              ],
            ),

            Row(
              children: [
                Container(
                  height: 160,
                  width: 235,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            SizedBox(width: 1),
                            Text(
                              vehicle.name,
                              style: TextStyle(
                                fontFamily: 'loginfonts.ttf',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Positioned(
                              top: 5,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Shadow/Glow effect
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer Light Circle
                                      Container(
                                        height: 15,
                                        width: 15,
                                        decoration: BoxDecoration(
                                          color: vehicle.color.withOpacity(
                                            0.25,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),

                                      // Inner Dark Circle
                                      Container(
                                        height: 10,
                                        width: 10,
                                        decoration: BoxDecoration(
                                          color: vehicle.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 2),
                            Text(
                              vehicle.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'loginfonts.ttf',
                              ),
                            ),
                            SizedBox(width: 2),
                            Text(
                              vehicle.time,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'loginfonts.ttf',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.pinkAccent,
                              size: 15,
                            ),
                            SizedBox(width: 2),
                            Text(
                              vehicle.date,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: "loginfonts.ttf",
                              ),
                            ),
                            SizedBox(width: 2),
                            Text(
                              vehicle.liveTime,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: "loginfonts.ttf",
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.pinkAccent,
                              size: 15,
                            ),
                            SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                vehicle.location,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily:
                                      "loginfonts.ttf", // یہاں سے .ttf ہٹا دیا
                                ),
                                softWrap: true, // یہ اب TextStyle سے باہر ہے
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 5),
                        child: Row(
                          children: [
                            Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.3,
                                    ), // شیڈو کا رنگ اور ہلکا پن
                                    blurRadius:
                                        12, // شیڈو کو کتنا دھندلا کرنا ہے
                                    spreadRadius:
                                        -3, // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.severe_cold_sharp,
                                color: Colors.pink,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: -3,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.satellite_alt_outlined,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.3,
                                    ), // شیڈو کا رنگ اور ہلکا پن
                                    blurRadius:
                                        12, // شیڈو کو کتنا دھندلا کرنا ہے
                                    spreadRadius:
                                        -3, // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.power_settings_new_outlined,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.3,
                                    ), // شیڈو کا رنگ اور ہلکا پن
                                    blurRadius:
                                        12, // شیڈو کو کتنا دھندلا کرنا ہے
                                    spreadRadius:
                                        -3, // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Image.asset(
                                  'assets/key.png',

                                  color: Colors.pink,
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 25,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.3,
                                    ), // شیڈو کا رنگ اور ہلکا پن
                                    blurRadius:
                                        12, // شیڈو کو کتنا دھندلا کرنا ہے
                                    spreadRadius:
                                        -3, // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  vehicle.distance,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'loginfonts.ttf',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.3,
                                    ), // شیڈو کا رنگ اور ہلکا پن
                                    blurRadius:
                                        12, // شیڈو کو کتنا دھندلا کرنا ہے
                                    spreadRadius:
                                        -3, // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 4),
                                  Container(
                                    height: 4,
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Container(
                                    height: 4,
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Container(
                                    height: 4,
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Container(
      //   height: 160,
      //   margin: const EdgeInsets.only(bottom: 12),
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //     borderRadius: BorderRadius.circular(2),
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withOpacity(.05),
      //         blurRadius: 10,
      //       ),
      //     ],
      //   ),
      //
      //   child:
      //   Row(
      //     children: [
      //
      //
      //
      //       Padding(
      //         padding: const EdgeInsets.only(bottom: 110),
      //         child: Image.asset(
      //           getLockImage(),
      //           width: 28,
      //         ),
      //       ),
      //
      //       const SizedBox(width: 8),
      //
      //       Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: [
      //
      //           Padding(
      //             padding: const EdgeInsets.only(top: 30 ),
      //             child: Image.asset(
      //               getCarImage(),
      //               width: 55,
      //             ),
      //           ),
      //
      //           const SizedBox(height: 10),
      //
      //           Text(
      //             vehicle.speed,
      //             style: const TextStyle(
      //               fontSize: 20,
      //               fontFamily: AppFonts.number,
      //             ),
      //           ),
      //
      //           const Text("kmph"),
      //         ],
      //       ),
      //
      //       const SizedBox(width: 20),
      //
      //       Expanded(
      //         child: Padding(
      //           padding: const EdgeInsets.symmetric(vertical: 15),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //
      //               Text(
      //                 vehicle.name,
      //                 style: const TextStyle(
      //                   fontSize: 16,
      //                   fontWeight: FontWeight.bold,
      //                   fontFamily: AppFonts.regular,
      //                 ),
      //               ),
      //
      //               const SizedBox(height: 6),
      //
      //               Row(
      //                 children: [
      //
      //                   Positioned(
      //                     top: 5,
      //                     child: Stack(
      //                       alignment: Alignment.center,
      //                       children: [
      //                         // Shadow/Glow effect
      //                         Stack(
      //                           alignment: Alignment.center,
      //                           children: [
      //                             // Outer Light Circle
      //                             Container(
      //                               height: 15,
      //                               width: 15,
      //                               decoration: BoxDecoration(
      //                                 color: vehicle.color.withOpacity(0.25),
      //                                 shape: BoxShape.circle,
      //                               ),
      //                             ),
      //
      //                             // Inner Dark Circle
      //                             Container(
      //                               height: 10,
      //                               width: 10,
      //                               decoration: BoxDecoration(
      //                                 color: vehicle.color,
      //                                 shape: BoxShape.circle,
      //                               ),
      //                             ),
      //                           ],
      //                         )
      //
      //
      //                       ],
      //                     ),
      //                   ),
      //
      //                   const SizedBox(width: 5),
      //
      //                   Text(
      //                     vehicle.status,
      //                     style: const TextStyle(fontSize: 10),
      //                   ),
      //
      //                   const SizedBox(width: 5),
      //
      //                   Expanded(
      //                     child: Text(
      //                       vehicle.time,
      //                       style: const TextStyle(fontSize: 10),
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //
      //               const SizedBox(height: 5),
      //
      //               Row(
      //                 children: [
      //
      //                   const Icon(
      //                     Icons.access_time,
      //                     color: Colors.pink,
      //                     size: 14,
      //                   ),
      //
      //                   const SizedBox(width: 3),
      //
      //                   Text(
      //                     vehicle.date,
      //                     style: const TextStyle(fontSize: 10),
      //                   ),
      //
      //                   const SizedBox(width: 5),
      //
      //                   Text(
      //                     vehicle.liveTime,
      //                     style: const TextStyle(fontSize: 10),
      //                   ),
      //                 ],
      //               ),
      //
      //               const SizedBox(height: 5),
      //
      //               Row(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //
      //                   const Icon(
      //                     Icons.location_on,
      //                     size: 14,
      //                     color: Colors.pink,
      //                   ),
      //
      //                   const SizedBox(width: 3),
      //
      //                   Expanded(
      //                     child: Text(
      //                       vehicle.location,
      //                       maxLines: 2,
      //                       overflow: TextOverflow.ellipsis,
      //                       style: const TextStyle(fontSize: 10),
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //               SizedBox(
      //                 height: 7,
      //               ),
      //               Padding(
      //                 padding:   EdgeInsets.only(top: 1),
      //                 child: Row(
      //                   children: [
      //                     Container(
      //                       height: 25,
      //                       width: 25,
      //                       decoration: BoxDecoration(
      //                         color: Colors.white,
      //                         borderRadius: BorderRadius.circular(8),
      //
      //                         boxShadow: [
      //                           BoxShadow(
      //                             color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
      //                             blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
      //                             spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
      //                             offset: const Offset(0, 10),
      //                           ),
      //                         ],
      //                       ),
      //                       child: Icon(Icons.severe_cold_sharp,color: Colors.pink,size: 16,),
      //
      //                     ),
      //                     SizedBox(
      //                       width: 8,
      //                     ),
      //                     Container(
      //                               height: 25,
      //                               width: 25,
      //                               decoration: BoxDecoration(
      //                                 color: Colors.white,
      //                                 borderRadius: BorderRadius.circular(8),
      //
      //                                 boxShadow: [
      //                                   BoxShadow(
      //                                     color: Colors.black.withOpacity(0.3),
      //                                     blurRadius: 12,
      //                                     spreadRadius: -3,
      //                                     offset: const Offset(0, 10),
      //                                   ),
      //                                 ],
      //                               ),
      //                               child: Icon(Icons.satellite_alt_outlined,color: Colors.green,size: 16,),
      //
      //                             ),
      //                     SizedBox(
      //                               width: 8,
      //                             ),
      //                             Container(
      //                               height: 25,
      //                               width: 25,
      //                               decoration: BoxDecoration(
      //                                 color: Colors.white,
      //                                 borderRadius: BorderRadius.circular(8),
      //
      //                                 boxShadow: [
      //                                   BoxShadow(
      //                                     color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
      //                                     blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
      //                                     spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
      //                                     offset: const Offset(0, 10),
      //                                   ),
      //                                 ],
      //                               ),
      //                               child: Icon(Icons.power_settings_new_outlined,color: Colors.green,size: 16,),
      //
      //                             ),
      //                     SizedBox(
      //                               width: 8,
      //                             ),
      //                             Container(
      //                               height: 25,
      //                               width: 25,
      //                               decoration: BoxDecoration(
      //                                 color: Colors.white,
      //                                 borderRadius: BorderRadius.circular(8),
      //
      //                                 boxShadow: [
      //                                   BoxShadow(
      //                                     color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
      //                                     blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
      //                                     spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
      //                                     offset: const Offset(0, 10),
      //                                   ),
      //                                 ],
      //                               ),
      //                               child: Padding(
      //                                 padding: const EdgeInsets.all(5.0),
      //                                 child: Image.asset('assets/key.png',
      //
      //                                   color: Colors.pink,
      //                                   colorBlendMode: BlendMode.srcIn,
      //                                 ),
      //                               ),
      //                             ),
      //                             SizedBox(
      //                               width: 8,
      //                             ),
      //                             Container(
      //                               height: 25,
      //                               width: 50,
      //                               decoration: BoxDecoration(
      //                               color: Colors.white,
      //                                 borderRadius: BorderRadius.circular(8),
      //
      //                                 boxShadow: [
      //                                   BoxShadow(
      //                                     color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
      //                                     blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
      //                                     spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
      //                                     offset: const Offset(0, 10),
      //                                   ),
      //                                 ],
      //                               ),
      //                               child:
      //                               Center(child: Text(vehicle.distance,style: TextStyle(fontSize: 8,fontFamily:'loginfonts.ttf' ),)),
      //
      //                             ),
      //                     SizedBox(
      //                       width: 10,
      //                     ),
      //                     Container(
      //                       height: 25,
      //                       width: 25,
      //                       decoration: BoxDecoration(
      //                         color: Colors.white,
      //                         borderRadius: BorderRadius.circular(8),
      //
      //                         boxShadow: [
      //                           BoxShadow(
      //                             color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
      //                             blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
      //                             spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
      //                             offset: const Offset(0, 10),
      //                           ),
      //                         ],
      //                       ),
      //                       child: Column(
      //                         children: [
      //                           SizedBox(
      //                             height: 4,
      //                           ),
      //                           Container(
      //                             height: 4,
      //                             width: 4,
      //                             decoration: BoxDecoration(
      //                                 color: Colors.grey,
      //                                 borderRadius: BorderRadius.circular(100)
      //                             ),
      //                           ),
      //                           SizedBox(
      //                             height: 2,
      //                           ),
      //                           Container(
      //                             height: 4,
      //                             width: 4,
      //                             decoration: BoxDecoration(
      //                                 color: Colors.grey,
      //                                 borderRadius: BorderRadius.circular(100)
      //                             ),
      //                           ),
      //                           SizedBox(
      //                             height: 2,
      //                           ),
      //                           Container(
      //                             height: 4,
      //                             width: 4,
      //                             decoration: BoxDecoration(
      //                                 color: Colors.grey,
      //                                 borderRadius: BorderRadius.circular(100)
      //                             ),
      //                           ),
      //                         ],
      //                       ),
      //
      //                     ),
      //
      //                   ],
      //
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
