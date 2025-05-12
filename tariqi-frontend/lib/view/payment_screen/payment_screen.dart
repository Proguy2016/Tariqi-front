import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/images/app_images.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/controller/payment_controller/payment_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentController(context: context));
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.offNamed(AppRoutesNames.homeScreen),
        ),
        title: Text("Choose Payment Method"),
        backgroundColor: AppColors.blackColor,
      ),
      body: Obx(
        () => HandlingView(
          requestState: controller.requestState.value,
          widget:
              controller.paymentMethod != null
                  ? ListView.builder(
                    itemExtent: ScreenSize.screenHeight! * 0.109,
                    itemCount: controller.paymentMethod!.data!.length,
                    itemBuilder:
                        (context, index) => Card(
                          color: AppColors.lightBalckColor,
                          elevation: 2,
                          shadowColor: AppColors.whiteColor,
                          child: ListTile(
                            onTap: () {
                              controller.proccessPaymentMethod(
                                controller
                                    .paymentMethod!
                                    .data![index]
                                    .paymentId!,
                              );
                            },
                            title: Text(
                              controller.paymentMethod!.data![index].nameEn!,
                            ),
                            subtitle: Text(
                              controller.paymentMethod!.data![index].nameAr!,
                            ),
                            leading: Image.network(
                              controller.paymentMethod!.data![index].logo!,
                            ),
                          ),
                        ),
                  )
                  : Center(child: Lottie.asset(AppImages.loading)),
        ),
      ),
    );
  }
}
