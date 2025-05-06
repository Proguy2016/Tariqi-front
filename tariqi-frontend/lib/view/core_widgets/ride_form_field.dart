import 'package:flutter/material.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';

Widget rideFormField({
  required void Function(String)? submitFunction,
  required TextEditingController textEditingController,
  required String hint,
  required String label,
  required String? Function(String?)? validate,
  String prifixtext = "",
  bool enabled = true,
}) {
  return TextFormField(
    validator: validate,
    onFieldSubmitted: submitFunction,
    controller: textEditingController,
    decoration: InputDecoration(
      prefixIcon: Container(
        width: ScreenSize.screenWidth! * 0.01,
        padding: EdgeInsets.only(left: ScreenSize.screenWidth! * 0.01),
        alignment: Alignment.centerLeft,
        child: Text(
          prifixtext,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      labelText: label,
      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      enabled: enabled,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lightBalckColor, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      filled: true,
      fillColor: AppColors.blackColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: ScreenSize.screenWidth! * 0.05,
        vertical: ScreenSize.screenHeight! * 0.02,
      ),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    ),
  );
}
