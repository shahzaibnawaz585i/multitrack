import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ListScreen(),
  ));
}

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16 ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Vehicle List",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _circleIcon(Icons.add, Colors.pink),
                      const SizedBox(width: 10),
                      _circleIcon(Icons.search, Colors.pink),
                      const SizedBox(width: 10),
                      Stack(
                        children: [
                          _circleIcon(Icons.notifications_none, Colors.cyan),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "0",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),

            /// 🔥 STATUS CARDS (Height adjusted to 190 to prevent overflow)
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: const [
                  StatusCard(color: Colors.purple, title: "All vehicles", count: "124"),
                  StatusCard(color: Colors.green, title: "Running", count: "10"),
                  StatusCard(color: Colors.orange, title: "Idle", count: "8"),
                  StatusCard(color: Colors.red, title: "Stop", count: "8"),
                  StatusCard(color: Color(0xFFEEEEEE), title: "Inactive", count: "45"),
                ],
              ),

            ),
            Container(
              height: 5,
              width: double.infinity,
              color: Colors.white,
            ),


            /// 🔥 VEHICLE LIST (SCROLLABLE)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                children: const [
                  VehicleCard(
                    name: "RJ14TF1654",
                    status: "RUNNING",
                    color: Colors.green,
                    speed: "17",
                    distance: "175.71 km",
                      time:"since 00d 00h 35m",
                      livetime:'08:06:59 PM',
                      location:"Heading towards Lower Mall, Anarkali, Lahore",
                      date:'June 28,2026'
                  ),
                  VehicleCard(
                    name: "RJ01RB3996",
                    status: "STOPPED",
                    color: Colors.red,
                    speed: "00",
                    distance: "7.72 km",
                      time:"since 00d 00h 35m",
                      livetime:'08:06:59 PM' ,
                    location:"GPO Chowk, Mall Road, Lahore",
                    date:'June 28,2026'
                  ),
                  VehicleCard(
                    name: "RJ14OK8241",
                    status: "Inactive",
                    color: Colors.grey,
                    speed: "00",
                    distance: "34.16 km",
                      time:"since 00d 00h 35m",
                      livetime:'08:06:59 PM',
                      location:'Liberty Market Parking, near Gaddafi Stadium, Lahore',
                      date:'June 28,2026'
                  ),
                  VehicleCard(
                    name: "RJ14OK8241",
                    status: "STOPPED",
                    color: Colors.red,
                    speed: "00",
                    distance: "31.16 km",
                      time:"since 00d 00h 35m",
                      livetime:'08:06:59 PM',
                      location:"MM Alam Road, Gulberg III, Lahore",
                      date:'June 28,2026'
                  ),
                  VehicleCard(
                    name: "RJ140P4561",
                    status: "RUNNING",
                    color: Colors.green,
                    speed: "45",
                    distance: "65.16 km",
                      time:"since 00d 00h 35m",
                      livetime:'08:06:59 PM',
                      location:'Main Boulevard Gulberg, near Kalma Chowk Flyover, Lahore',
                      date:'June 28,2026'
                  ),
                  VehicleCard(
                    name: "RK15OK8551",
                    status: "Idel",
                    color: Colors.yellow,
                    speed: "00",
                    distance: "44.16 km",
                      time:"since 00d 00h 35m",
                      livetime:'08:06:59 PM',
                      location:"Liberty Market Parking, near Gaddafi Stadium, Lahore",
                      date:'June 28,2026'


                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// 🔥 STATUS CARD DESIGN
class StatusCard extends StatelessWidget {
  final Color color;
  final String title;
  final String count;

  const StatusCard({
    super.key,
    required this.color,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12, top: 10),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          /// 🔹 MAIN CARD BODY
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 45),
            padding: const EdgeInsets.only(top: 45, bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          /// 🔥 FLOATING ICON DESIGN
          Positioned(
            top: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shadow/Glow effect
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.9),
                  ),
                ),
                Container(
                  height: 40.5,
                  width: 40.5,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.9),
                            blurRadius: 10,
                            spreadRadius: 13
                        )
                      ]
                  ),
                ),
                // Inner Colored Circle
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.8), color],
                    ),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }

}


/// 🔥 VEHICLE CARD DESIGN
class VehicleCard extends StatelessWidget {
  final String name;
  final String status;
  final Color color;
  final String speed;
  final String distance;
  final String time;
  final String livetime;
  final String location;
  final String date;

  const VehicleCard({
    super.key,
    required this.name,
    required this.status,
    required this.color,
    required this.speed,
    required this.distance,
    required this.time,
    required this.livetime,
    required this.location,
    required this.date,
  });
  /// 🔥 STATUS IMAGE FUNCTION
  String getStatusImage(String status) {
    final s = status.toLowerCase().trim();

    if (s == "running") {
      return "assets/lockgreen.png";
    } else if (s == "stopped") {
      return "assets/lock_stop.png";
    } else if (s == "idle" || s == "idel") {
      return "assets/lock-yellow.png";
    } else if (s == "inactive") {
      return "assets/lock_inactive.png";
    } else {
      return "assets/lock_inactive.png";
    }
  }
  String getStatusImages(String status) {
    final s = status.toLowerCase().trim();

    if (s == "running") {
      return "assets/green_car.png";
    } else if (s == "stopped") {
      return "assets/red_car.png";
    } else if (s == "idle" || s == "idel") {
      return "assets/yellow_car.png";
    } else if (s == "inactive") {
      return "assets/grey_car.png";
    } else {
      return "assets//grey_car.png";
    }
  }


  @override
  Widget build(BuildContext context) {
    return
      Container(
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
          child:Row(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Container(
                      height: 30,
                      width: 30,
                      child: Image.asset(  getStatusImage(status),
                        fit: BoxFit.contain,

                      ),

                    ),
                  ),

                ],
              ),
              SizedBox(
                width: 10,
              ),
              Row(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 40,
                      ),
                      Container(
                        height:50,
                        width: 60,

                        child: Image.asset(  getStatusImages(status),
                          fit: BoxFit.contain,

                        ),


                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(speed,style: TextStyle(fontFamily: 'numberfonts',fontSize: 20),),
                      Text('kmph',style: TextStyle(fontFamily: 'medium.ttf'),)
                    ],
                  ),


                ],
              ),


              Row(
                children: [
                  Container(
                    height: 160,
                    width:235 ,
                    child:
                    Column(
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              Text(name,style: TextStyle(
                                fontFamily: 'loginfonts.ttf',fontSize: 16
                              ),)
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
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
                                    Container(
                                      height: 15,
                                      width: 15,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color.withOpacity(0.2),
                                      ),
                                    ),

                                    // Inner Colored Circle
                                    Container(
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [color.withOpacity(0.8), color],

                                        ),
                                      ),
                                    ),


                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 2,
                              ),
                              Text(status,style: TextStyle(
                                fontSize: 10,fontFamily: 'loginfonts.ttf',
                              ),),
                              SizedBox(
                                width: 2,
                              ),
                              Text(time,style: TextStyle(
                                fontSize: 10,fontFamily: 'loginfonts.ttf',
                              ),),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,color: Colors.pinkAccent,size: 15,),
                              SizedBox(
                                width: 2,
                              ),
                              Text(date,style: TextStyle(fontSize: 10,fontFamily: "loginfonts.ttf"),),
                              SizedBox(
                                width: 2,
                              ),
                              Text(livetime,style: TextStyle(fontSize: 10,fontFamily: "loginfonts.ttf"),),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,color: Colors.pinkAccent,size: 15,),
                              SizedBox(
                                width: 2,
                              ),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: "loginfonts.ttf", // یہاں سے .ttf ہٹا دیا
                                  ),
                                  softWrap: true, // یہ اب TextStyle سے باہر ہے
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10,left: 5),
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
                                      color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
                                      blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
                                      spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.severe_cold_sharp,color: Colors.pink,size: 16,),

                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
                                      blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
                                      spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.satellite_alt_outlined,color: Colors.green,size: 16,),

                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                 
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
                                      blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
                                      spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.power_settings_new_outlined,color: Colors.green,size: 16,),

                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
                                      blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
                                      spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Image.asset('assets/key.png',

                                    color: Colors.pink,
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 25,
                                width: 50,
                                decoration: BoxDecoration(
                                color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
                                      blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
                                      spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child:
                                Center(child: Text(distance,style: TextStyle(fontSize: 8,fontFamily:'loginfonts.ttf' ),)),

                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), // شیڈو کا رنگ اور ہلکا پن
                                      blurRadius: 12,                       // شیڈو کو کتنا دھندلا کرنا ہے
                                      spreadRadius: -3,                    // یہ سائیڈوں سے شیڈو کو چھپا دے گا (صرف نیچے دکھائے گا)
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Container(
                                      height: 4,
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(100)
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Container(
                                      height: 4,
                                      width: 4,
                                      decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(100)
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Container(
                                      height: 4,
                                      width: 4,
                                      decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(100)
                                      ),
                                    ),
                                  ],
                                ),

                              ),


                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )
               
            ],
          )

      );
  }
}
 