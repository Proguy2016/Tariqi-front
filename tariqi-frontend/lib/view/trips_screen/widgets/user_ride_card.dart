import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/time_format.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/controller/user_trips_controller/user_trips_controller.dart';
import 'package:tariqi/models/user_rides_model.dart';
import 'package:tariqi/const/class/screen_size.dart';

Widget userRideCard({
  required UserTripsController controller,
  required UserRidesModel userRidesModel,
}) {
  return Card(
    color: AppColors.lightBalckColor,
    shadowColor: AppColors.otpBorder,
    elevation: 2,
    margin: EdgeInsets.only(
      bottom: ScreenSize.screenHeight! * 0.02,
      right: ScreenSize.screenWidth! * 0.04,
      left: ScreenSize.screenWidth! * 0.04,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSize.screenWidth! * 0.02,
        vertical: ScreenSize.screenHeight! * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ScreenSize.screenHeight! * 0.02,
        children: [
          SizedBox(
            width: ScreenSize.screenWidth! * 0.9,
            child: Stack(
              children: [
                Text(
                  "Ride Id : ${userRidesModel.rideId}",
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth! * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),

                Visibility(
                  visible: userRidesModel.status == "accepted" ? true : false,
                  child: Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap:
                          () => controller.goToChatScreen(
                            rideId: userRidesModel.rideId!,
                          ),
                      child: Container(
                        padding: EdgeInsets.all(
                          ScreenSize.screenWidth! * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_sharp,
                          color: AppColors.whiteColor,
                          size: ScreenSize.screenWidth! * 0.03,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ScreenSize.screenWidth! * 0.5,
                ),
                child: Text(
                  "Req Id : ${controller.requestId.isEmpty ? "" : controller.requestId}",

                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: ScreenSize.screenWidth! * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),
              ),
              Text(
                "Status : ${userRidesModel.status}",
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth! * 0.04,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteColor,
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ScreenSize.screenWidth! * 0.5,
                ),
                child: Text(
                  "Created At : ${formatDateTime(userRidesModel.createdAt!)}",
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: ScreenSize.screenWidth! * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),
              ),

              Text(
                "Available Seats : ${userRidesModel.availableSeats}",
                style: TextStyle(
                  fontSize: ScreenSize.screenWidth! * 0.04,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteColor,
                ),
              ),
            ],
          ),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              "Driver : ${userRidesModel.driver?.firstName} ${userRidesModel.driver?.lastName}",
              style: TextStyle(
                fontSize: ScreenSize.screenWidth! * 0.04,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
              ),
            ),
            Text(
              "Car : ${userRidesModel.driver?.carDetails?.make} ${userRidesModel.driver?.carDetails?.model}",
              style: TextStyle(
                fontSize: ScreenSize.screenWidth! * 0.04,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
              ),
            ),
          ]),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed:
                    () =>
                        controller.ridesAction(status: userRidesModel.status!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  controller.userRideAction(status: userRidesModel.status!),
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth! * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  if (userRidesModel.status == "accepted") {
                    Get.toNamed(
                      AppRoutesNames.trackRequestScreen,
                      arguments: {"userRidesModel": userRidesModel},
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  userRidesModel.status == "accepted" ? "Track" : "Waiting",
                  style: TextStyle(
                    fontSize: ScreenSize.screenWidth! * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
