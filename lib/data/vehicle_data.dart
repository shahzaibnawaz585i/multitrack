import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';

class VehicleData {
  static List<VehicleModel> vehicles = [
    VehicleModel(
      name: "RJ14TF1654",
      status: "RUNNING",
      color: Colors.green,
      speed: "17",
      distance: "175.71 km",
      time: "since 00d 00h 35m",
      liveTime: "08:06:59 PM",
      location: "Heading towards Lower Mall, Anarkali, Lahore",
      date: "June 28,2026",
    ),

    VehicleModel(
      name: "RJ01RB3996",
      status: "STOPPED",
      color: Colors.red,
      speed: "00",
      distance: "7.72 km",
      time: "since 00d 00h 35m",
      liveTime: "08:06:59 PM",
      location: "GPO Chowk, Mall Road, Lahore",
      date: "June 28,2026",
    ),

    VehicleModel(
      name: "RJ14OK8241",
      status: "Inactive",
      color: Colors.grey,
      speed: "00",
      distance: "34.16 km",
      time: "since 00d 00h 35m",
      liveTime: "08:06:59 PM",
      location: "Liberty Market Parking, near Gaddafi Stadium, Lahore",
      date: "June 28,2026",
    ),

    VehicleModel(
      name: "RJ14OK8241",
      status: "STOPPED",
      color: Colors.red,
      speed: "00",
      distance: "31.16 km",
      time: "since 00d 00h 35m",
      liveTime: "08:06:59 PM",
      location: "MM Alam Road, Gulberg III, Lahore",
      date: "June 28,2026",
    ),

    VehicleModel(
      name: "RJ140P4561",
      status: "RUNNING",
      color: Colors.green,
      speed: "45",
      distance: "65.16 km",
      time: "since 00d 00h 35m",
      liveTime: "08:06:59 PM",
      location: "Main Boulevard Gulberg, near Kalma Chowk Flyover, Lahore",
      date: "June 28,2026",
    ),

    VehicleModel(
      name: "RK15OK8551",
      status: "Idle",
      color: Colors.orange,
      speed: "00",
      distance: "44.16 km",
      time: "since 00d 00h 35m",
      liveTime: "08:06:59 PM",
      location: "Liberty Market Parking, near Gaddafi Stadium, Lahore",
      date: "June 28,2026",
    ),
  ];
  List<VehicleModel> vehicleList = VehicleData.vehicles;
}
