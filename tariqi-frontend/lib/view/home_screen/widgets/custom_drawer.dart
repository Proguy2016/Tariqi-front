import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/home_controller/home_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

Widget customDrawer({
  required void Function() messagesFunction,
  required HomeController homeController,
}) {
  return Container(
    width: ScreenSize.screenWidth! * 0.65,
    margin: EdgeInsets.only(
      bottom: ScreenSize.screenHeight! * 0.01,
      top: ScreenSize.screenHeight! * 0.225,
    ),

    decoration: BoxDecoration(
      color: AppColors.lightBalckColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(30),
      ),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _drawerHeader(
          messagesFunction: messagesFunction,
          homeController: homeController,
        ),
        _drawerItem(
          title: "Your Trips",
          navigationFunction:
              () => homeController.drawerNavigationFunc(title: "trips"),
        ),
        _drawerItem(
          title: "Payment",
          navigationFunction:
              () => homeController.drawerNavigationFunc(title: "payment"),
        ),
        _drawerItem(
          title: "Notifications",
          navigationFunction:
              () => homeController.drawerNavigationFunc(title: "notifications"),
        ),


        _drawerItem(
          title: "Logout",
          navigationFunction:
              () => homeController.drawerNavigationFunc(title: "logout"),
        ),
      ],
    ),
  );
}

Widget _drawerHeader({
  required void Function() messagesFunction,
  required HomeController homeController,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.blackColor,

      borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
    ),
    width: ScreenSize.screenWidth! * 0.65,
    padding: EdgeInsets.symmetric(
      vertical: ScreenSize.screenHeight! * 0.02,
      horizontal: ScreenSize.screenWidth! * 0.02,
    ),
    child: Column(
      spacing: ScreenSize.screenHeight! * 0.01,
      children: [
        Row(
          spacing: ScreenSize.screenWidth! * 0.03,
          children: [
            CircleAvatar(
              radius: ScreenSize.screenWidth! * 0.08,
              backgroundColor: AppColors.whiteColor,
              child: Icon(
                Icons.person,
                color: AppColors.blackColor,
                size: ScreenSize.screenWidth! * 0.09,
              ),
            ),

            Obx(
              () => HandlingView(
                requestState: homeController.requestState.value,
                widget:
                    homeController.clientInfo.isNotEmpty
                        ? Column(
                          spacing: ScreenSize.screenHeight! * 0.01,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              homeController.clientInfo.first.firstName != null
                                  ? "${homeController.clientInfo.first.firstName!} ${homeController.clientInfo.first.lastName!}"
                                  : "",
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: ScreenSize.screenWidth! * 0.05,
                              ),
                            ),

                            Text(
                              homeController.clientInfo.first.email != null
                                  ? homeController.clientInfo.first.email!
                                  : "",
                              style: TextStyle(
                                overflow: TextOverflow.fade,
                                fontSize: ScreenSize.screenWidth! * 0.03,
                                color: AppColors.whiteColor,
                              ),
                            ),
                            Text(
                              homeController.clientInfo.first.phoneNumber !=
                                      null
                                  ? homeController.clientInfo.first.phoneNumber!
                                  : "",
                              style: TextStyle(
                                overflow: TextOverflow.fade,
                                fontSize: ScreenSize.screenWidth! * 0.03,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ],
                        )
                        : Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
        Divider(color: AppColors.whiteColor, thickness: 2),
        // GestureDetector(
        //   onTap: messagesFunction,

        //   child: Padding(
        //     padding: EdgeInsets.only(right: ScreenSize.screenWidth! * 0.05),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Text("Messages"),
        //         Icon(Icons.arrow_forward_ios, size: 15),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    ),
  );
}

Widget _drawerItem({
  required String title,
  required void Function() navigationFunction,
}) {
  return GestureDetector(
    onTap: navigationFunction,
    child: Padding(
      padding: EdgeInsets.only(
        left: ScreenSize.screenWidth! * 0.02,
        right: ScreenSize.screenWidth! * 0.02,
      ),
      child: Column(
        spacing: ScreenSize.screenHeight! * 0.02,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.lightBalckColor,
            elevation: 0,
            child: Container(
              width: ScreenSize.screenWidth,
              padding: EdgeInsets.symmetric(
                vertical: ScreenSize.screenHeight! * 0.015,
                horizontal: ScreenSize.screenWidth! * 0.02,
              ),
              child: Text(
                title,
                style: TextStyle(fontSize: ScreenSize.screenWidth! * 0.04),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
