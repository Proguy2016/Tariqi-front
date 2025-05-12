import 'package:flutter/material.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/controller/create_ride_controller/create_ride_controller.dart';
import 'package:tariqi/view/core_widgets/ride_form_field.dart';
import 'package:tariqi/const/functions/field_valid.dart';
import 'package:tariqi/const/colors/app_colors.dart';

Widget buildInputRideInfo({required CreateRideController controller}) {
    return Form(
      key: controller.formKey,
      child: Column(
        spacing: ScreenSize.screenHeight! * 0.03,
        children: [
          rideFormField(
            validate: (value) {
              return validFields(
                val: value!,
                type: "pick",
                fieldName: "Pick Point",
                minVal: 1,
                maxVal: 350,
              );
            },
            label: "Pick Point",
            enabled: false,
            submitFunction: (value) {},
            textEditingController: controller.pickPointController,
            hint: "Enter pickup point",
          ),

          rideFormField(
            validate: (value) {
              return validFields(
                val: value!,
                type: "target",
                fieldName: "Target Point",
                minVal: 1,
                maxVal: 350,
              );
            },
            label: "Target Point",
            submitFunction:
                (value) => controller.getTargetLocation(location: value),
            textEditingController: controller.targetPointController,
            hint: "Enter Target point",
          ),

          MaterialButton(
            padding: EdgeInsets.symmetric(
              vertical: ScreenSize.screenHeight! * 0.01,
              horizontal: ScreenSize.screenWidth! * 0.05,
            ),
            color: AppColors.blackColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.blueColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            onPressed: () {
              controller.createRide();
            },
            child: Text(
              "Create Ride",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }