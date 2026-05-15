import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final double size;

  const AppIcon({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    double iconSize = size * 0.9;
    double padding = size * 0.05;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset("assets/images/cocochat_icon.png",
            height: iconSize, width: iconSize),
      ),
    );
  }
}
