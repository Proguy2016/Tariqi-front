import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/home_controller/home_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/core_widgets/ride_form_field.dart';

Widget chooseRideKind({
  required void Function()? startRide,
  required void Function(String)? pickPointFunction,
  required TextEditingController textEditingController,
  required HomeController homeController,
}) => Container(
  color: AppColors.blackColor,
  padding: EdgeInsets.symmetric(
    horizontal: ScreenSize.screenWidth! * 0.02,
    vertical: ScreenSize.screenHeight! * 0.02,
  ),
  child: Row(
    spacing: ScreenSize.screenHeight! * 0.02,
    children: [
      Expanded(
        child: rideFormField(
          fieldIcon: Obx(
            () => HandlingView(
              requestState: homeController.requestState.value,
              widget: Icon(Icons.location_on),
            ),
          ),
          validate: (p0) {
            return null;
          },
          label: "Pick Point",
          submitFunction: (value) {
            if (pickPointFunction != null) {
              pickPointFunction(value);
            }
          },
          textEditingController: textEditingController,
          hint: "Enter pickup point",
        ),
      ),

      MaterialButton(
        color: AppColors.blackColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.blueColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        onPressed: startRide,
        child: Text(
          "Start",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  ),
);
