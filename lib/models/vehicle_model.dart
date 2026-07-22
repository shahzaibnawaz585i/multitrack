import 'package:flutter/material.dart';

class VehicleModel {
  final String name;
  final String status;
  final Color color;
  final String speed;
  final String distance;
  final String time;
  final String liveTime;
  final String location;
  final String date;
  final double latitude;
  final double longitude;

  const VehicleModel({
    required this.name,
    required this.status,
    required this.color,
    required this.speed,
    required this.distance,
    required this.time,
    required this.liveTime,
    required this.location,
    required this.date,
    required this.latitude,
    required this.longitude,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      color: Colors.green,
      speed: json['speed'].toString(),
      distance: json['distance'] ?? '',
      time: json['time'] ?? '',
      liveTime: json['liveTime'] ?? '',
      location: json['location'] ?? '',
      date: json['date'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 31.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 74.3587,
    );
  }
}
