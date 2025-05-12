import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/controller/notification_controller/notification_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/notification_screen/widgets/notiication_card.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Screen"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.offNamed(AppRoutesNames.homeScreen);
          },
        ),
      ),
      body: SafeArea(
        child: Obx(
          () => HandlingView(
            requestState: controller.requestState.value,
            widget: ListView.builder(
              itemCount:
                  controller.remoteNotificationList.isNotEmpty
                      ? controller.remoteNotificationList.length
                      : controller.staticNotificationList.length,
              itemBuilder: (context, index) {
                return notificationCard(
                  notification:
                      controller.remoteNotificationList.isNotEmpty
                          ? controller.remoteNotificationList[index]
                          : controller.staticNotificationList[index],
                  changeStatusFunction:
                      () => controller.changeReadStatus(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
