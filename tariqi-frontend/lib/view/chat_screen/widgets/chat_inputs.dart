import 'package:flutter/material.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/field_valid.dart';

Widget chatInput({
  required void Function() sendMessageFunc,
  required TextEditingController messageFieldController,
  required GlobalKey<FormState> messageFormKey,
}) {
  return Form(
    key: messageFormKey,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSize.screenWidth! * 0.02,
      ),
      child: Row(
        spacing: ScreenSize.screenWidth! * 0.05,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: ScreenSize.screenHeight! * 0.01),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.whiteColor),
              ),
              child: TextFormField(
                controller: messageFieldController,
                validator: (value) {
                  return validFields(
                    val: value!,
                    type: "message",
                    fieldName: "Message",
                    minVal: 1,
                    maxVal: 350,
                  );
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.screenWidth! * 0.05,
                    vertical: ScreenSize.screenHeight! * 0.01,
                  ),
                  border: InputBorder.none,
                  hintText: "Type your message",
                  hintStyle: TextStyle(color: AppColors.whiteColor),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: sendMessageFunc,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blueColor,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.all(ScreenSize.screenWidth! * 0.02),
              child: Transform.rotate(
                angle: 270,
                child: Icon(Icons.send, size: 25),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
