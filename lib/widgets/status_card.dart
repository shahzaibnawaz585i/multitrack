import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

class StatusCard extends StatelessWidget {
  final Color color;
  final String title;
  final String count;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusCard({
    super.key,
    required this.color,
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12, top: 10),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 45),
              padding: const EdgeInsets.only(top: 45, bottom: 15),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(.08)
                    : context.appSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.appTextColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: TextStyle(color: context.appSecondaryText),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                      color: context.isDarkTheme
                          ? const Color(0xFF555555)
                          : Colors.grey.shade400,
                      boxShadow: [
                        BoxShadow(
                          color: (context.isDarkTheme
                                  ? Colors.black
                                  : Colors.grey)
                              .withOpacity(0.9),
                          blurRadius: 10,
                          spreadRadius: 13,
                        ),
                      ],
                    ),
                  ),
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
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
