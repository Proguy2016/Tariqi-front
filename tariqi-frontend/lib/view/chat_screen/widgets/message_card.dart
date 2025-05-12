import 'package:flutter/material.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/time_format.dart';
import 'package:tariqi/models/messages_model.dart';

Widget buildMessageCard({required MessagesModel message}) {
  return Align(
    alignment:
        message.senderType == "client"
            ? Alignment.centerLeft
            : Alignment.centerRight,
    child: Container(
      width: ScreenSize.screenWidth! * 0.6,
      padding: EdgeInsets.only(
        left:
            message.senderType == "client" ? 0 : ScreenSize.screenWidth! * 0.05,
        right:
            message.senderType == "client" ? 0 : ScreenSize.screenWidth! * 0.03,
        top: ScreenSize.screenHeight! * 0.008,
        bottom: ScreenSize.screenHeight! * 0.008,
      ),
      margin: EdgeInsets.symmetric(
        horizontal: ScreenSize.screenWidth! * 0.03,
      ),
      decoration: BoxDecoration(
        color:
            message.senderType == "client"
                ? AppColors.whiteColor
                : AppColors.blueColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
          bottomLeft:
              message.senderType == "client"
                  ? Radius.circular(0)
                  : Radius.circular(25),
          bottomRight:
              message.senderType == "client"
                  ? Radius.circular(25)
                  : Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          Container(
            alignment:
                message.senderType == "client"
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child: Text(
              message.content!,
              overflow: TextOverflow.clip,
             
              style: TextStyle(
                fontSize: 16,
                color:
                    message.senderType == "client"
                        ? AppColors.blackColor
                        : AppColors.whiteColor,
              ),
            ),
          ),

          Container(
            alignment:
                message.senderType == "client"
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
            child: Text(
              formatDateTimeChat(message.timestamp!),
              style: TextStyle(
                fontSize: 10,
                color:
                    message.senderType == "client"
                        ? AppColors.blackColor
                        : AppColors.whiteColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
