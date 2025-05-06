import 'package:flutter/material.dart';
import 'package:tariqi/const/class/screen_size.dart';

class CustomBtn extends StatelessWidget {
  final String text;
  final Color? btnColor;
  final Color textColor;
  final void Function() btnFunc;
  const CustomBtn({
    super.key,
    required this.text,
    this.btnColor,
    this.textColor = Colors.white,
    required this.btnFunc,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: 0,
      padding: EdgeInsets.symmetric(
        vertical: ScreenSize.screenWidth! * 0.03,
        horizontal: ScreenSize.screenWidth! * 0.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      color: btnColor,
      textColor: textColor,
      onPressed: btnFunc,
      child: Text(text, style: TextStyle(fontSize: 24)),
    );
  }
}
