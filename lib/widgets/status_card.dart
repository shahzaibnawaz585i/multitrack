import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../theme/app_theme_tokens.dart';

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
        width: 106,
        height: 115,
        margin: const EdgeInsets.only(right: 10, top: 2),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 28),
              padding: const EdgeInsets.only(top: 28, bottom: 13),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.08)
                    : context.containerColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (context.appTokens.containerBorderColor ??
                          Colors.transparent),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(title),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.mutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.9),
                          blurRadius: 6,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 27,
                    width: 27,
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
                      size: 16,
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
