import 'package:flutter/material.dart';

class SettingItem extends StatelessWidget {
  final String title; 
  final String? description; 
  final Function? onClick;
  final IconData icon;
  const SettingItem({super.key, required this.title, this.description, required this.icon, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick != null ? () =>  onClick!() : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 25,
            ),
            const SizedBox(width: 15,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 2,),
                description != null ? 
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 12
                    ),
                  ) : 
                  const SizedBox()
              ],
            )
          ],
        ),
      ),
    );
  }
}