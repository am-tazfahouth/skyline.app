import 'package:flutter/material.dart';
import 'package:sky_line/core/config/app_theme.dart';

class SettingCard extends StatelessWidget {
  final String title; 
  final List<Widget> options;
  const SettingCard({super.key, required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.surfaceFor(Theme.of(context).brightness);
    final cardColor = surface.colorContainer;
    
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(6)
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              ...options
            ],
          ),
        ),
      ),
    );
  }
}