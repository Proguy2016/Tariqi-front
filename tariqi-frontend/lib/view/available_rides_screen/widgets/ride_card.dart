import 'package:flutter/material.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/available_rides_controller/available_rides_controller.dart';
import 'package:tariqi/models/availaible_rides_model.dart';

Widget rideCard({
  required int index,
  required void Function() onRideTapFunction,
  required void Function() bookRideFunction,
  required AvailaibleRidesModel rides,
  required AvailableRidesController availableRidesController,
}) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: AppColors.whiteColor, width: 0.5),
    ),

    elevation: 5,
    shadowColor: AppColors.mediumBlueColor,
    margin: EdgeInsets.only(
      top: ScreenSize.screenHeight! * 0.02,
      right: ScreenSize.screenWidth! * 0.04,
      left: ScreenSize.screenWidth! * 0.04,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: ScreenSize.screenHeight! * 0.02,
        horizontal: ScreenSize.screenWidth! * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: ScreenSize.screenWidth! * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ScreenSize.screenHeight! * 0.015,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _rideCardText(title: "Available Seats : "),

                    _rideCardText(title: "${rides.availableSeats}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _rideCardText(title: "Distance To Pick : "),

                    _rideCardText(
                      title:
                          "${(rides.driverToPickup!.distance! / 10000).roundToDouble()} KM",
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _rideCardText(title: "Duration To Pick : "),

                    _rideCardText(
                      title:
                          "${(rides.driverToPickup!.duration! / 3600).roundToDouble()} Min",
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MaterialButton(
                      color: AppColors.blueColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      onPressed: onRideTapFunction,
                      child: Text(
                        "View Route",
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: ScreenSize.screenWidth! * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    MaterialButton(
                      color: AppColors.greenColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      onPressed: () {
                        availableRidesController.bookRide(
                          rideId: rides.rideId!,
                        );
                      },
                      child: Text(
                        "Book Ride",
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: ScreenSize.screenWidth! * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _rideCardText({required String title}) {
  return Text(
    title,
    style: TextStyle(
      color: AppColors.whiteColor,
      fontSize: ScreenSize.screenWidth! * 0.035,
      fontWeight: FontWeight.bold,
    ),
  );
}
