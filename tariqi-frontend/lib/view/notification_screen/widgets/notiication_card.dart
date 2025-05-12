import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/notification_controller/notification_controller.dart';
import 'package:tariqi/models/notification_model.dart';

Widget notificationCard({
  required NotificationModel notification,
  required void Function() changeStatusFunction,
}) {
  return GetBuilder<NotificationController>(
    builder:
        (controller) => Card(
          color: notification.isRead ? Colors.transparent : AppColors.greyColor,
          margin: EdgeInsets.symmetric(horizontal: ScreenSize.screenWidth! * 0.02 , 
          
          vertical: ScreenSize.screenHeight! * 0.007,
          ),
          child: Container(
            padding: EdgeInsets.all(ScreenSize.screenWidth! * 0.02),
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                size: ScreenSize.screenWidth! * 0.08,
              ),
              title: Text(notification.title),
              subtitle: Text(notification.body),
              trailing:
                  notification.isRead
                      ? Icon(
                        Icons.mark_chat_read,
                        size: ScreenSize.screenWidth! * 0.05,
                      )
                      : GestureDetector(
                        onTap: changeStatusFunction,
                        child: Icon(
                          Icons.mark_chat_unread,
                          size: ScreenSize.screenWidth! * 0.05,
                        ),
                      ),
            ),
          ),
        ),
  );
}
