import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/field_valid.dart';
import 'package:tariqi/const/functions/pop_func.dart';
import 'package:tariqi/controller/auth_controllers/signup_controller.dart';
import 'package:tariqi/view/core_widgets/custom_btn.dart';
import 'package:tariqi/view/core_widgets/custom_form_field.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/core_widgets/pop_widget.dart';
import 'package:tariqi/const/class/request_state.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(SignupController());
    return PopScopeWidget(
      popAction: (didPop, res) {
        popFunc(didpop: didPop, result: exit(0));
      },
      childWidget: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.screenWidth! * 0.05,
                ),
                width: ScreenSize.screenWidth,
                child: Obx(
                  () => HandlingView(
                    requestState: controller.requestState.value,
                    widget: Form(
                      key: controller.signUpformKey,
                      child: Column(
                        spacing: ScreenSize.screenWidth! * 0.15,
                        children: [
                          _signUpPageHeader(),
                          _buildRoleSelection(controller),
                          _buildSignUpInputs(controller: controller),
                          Obx(() => controller.selectedRole.value == "driver"
                              ? _buildDriverInputs(controller: controller)
                              : const SizedBox.shrink()),
                          _signUpPageActions(
                              signUpFunction: () => controller.signUpFunc(),
                              controller: controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signUpPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create a New Account",
          style: TextStyle(
            fontSize: 30,
            color: AppColors.blueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection(SignupController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Account Type",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Obx(() => GestureDetector(
                    onTap: () => controller.setRole("client"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: controller.selectedRole.value == "client"
                            ? AppColors.blueColor
                            : Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Client",
                          style: TextStyle(
                            color: controller.selectedRole.value == "client"
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Obx(() => GestureDetector(
                    onTap: () => controller.setRole("driver"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: controller.selectedRole.value == "driver"
                            ? AppColors.blueColor
                            : Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Driver",
                          style: TextStyle(
                            color: controller.selectedRole.value == "driver"
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )),
            ),
          ],
        ),
        SizedBox(height: ScreenSize.screenHeight! * 0.02),
      ],
    );
  }

  Widget _buildSignUpInputs({required SignupController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ScreenSize.screenWidth! * 0.04,
      children: [
        Column(
          spacing: ScreenSize.screenWidth! * 0.1,
          children: [
            CustomFormField(
              controller: controller.firstNameController,
              hintText: "Enter Your First Name",
              labelText: "First Name",
              fieldIcon: const Icon(Icons.person, size: 25),
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "text",
                  fieldName: "First Name",
                  maxVal: 30,
                  minVal: 2,
                );
              },
            ),
            CustomFormField(
              controller: controller.lastNameController,
              hintText: "Enter Your Last Name",
              labelText: "Last Name",
              fieldIcon: const Icon(Icons.person_outline, size: 25),
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "text",
                  fieldName: "Last Name",
                  maxVal: 30,
                  minVal: 2,
                );
              },
            ),
            CustomFormField(
              controller: controller.ageController,
              hintText: "Enter Your Age",
              labelText: "Age",
              fieldIcon: const Icon(Icons.cake, size: 25),
              textType: TextInputType.number,
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "number",
                  fieldName: "Age",
                  maxVal: 100,
                  minVal: 2,
                );
              },
            ),
            CustomFormField(
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "email",
                  fieldName: "Email",
                  maxVal: 100,
                  minVal: 11,
                );
              },
              controller: controller.emailController,
              hintText: "Enter Your Email",
              labelText: "Email",
              fieldIcon: const Icon(Icons.alternate_email, size: 25),
            ),
            CustomFormField(
              controller: controller.passwordController,
              hintText: "Enter Your Password",
              labelText: "Password",
              secureText: controller.showPass.value,
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "password",
                  fieldName: "Password",
                  maxVal: 30,
                  minVal: 6,
                );
              },
              fieldIcon: IconButton(
                onPressed: () {
                  controller.toggleShowPass();
                },
                icon: controller.showPass.value
                    ? const Icon(Icons.visibility_off_outlined, size: 25)
                    : const Icon(Icons.visibility_outlined, size: 25),
              ),
            ),
            CustomFormField(
              controller: controller.mobileController,
              hintText: "Enter Your Mobile Number",
              labelText: "Mobile",
              fieldIcon: const Icon(Icons.phone, size: 25),
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "mobile",
                  fieldName: "Mobile Number",
                  maxVal: 15,
                  minVal: 10,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverInputs({required SignupController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          "Car Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        CustomFormField(
          controller: controller.carMakeController,
          hintText: "Toyota, Honda, etc.",
          labelText: "Car Make",
          fieldIcon: const Icon(Icons.drive_eta, size: 25),
          validator: (val) {
            return validFields(
              val: val!,
              type: "text",
              fieldName: "Car Make",
              maxVal: 50,
              minVal: 2,
            );
          },
        ),
        const SizedBox(height: 15),
        CustomFormField(
          controller: controller.carModelController,
          hintText: "Corolla, Civic, etc.",
          labelText: "Car Model",
          fieldIcon: const Icon(Icons.car_repair, size: 25),
          validator: (val) {
            return validFields(
              val: val!,
              type: "text",
              fieldName: "Car Model",
              maxVal: 50,
              minVal: 2,
            );
          },
        ),
        const SizedBox(height: 15),
        CustomFormField(
          controller: controller.licensePlateController,
          hintText: "ABC-1234",
          labelText: "License Plate",
          fieldIcon: const Icon(Icons.confirmation_number, size: 25),
          validator: (val) {
            return validFields(
              val: val!,
              type: "text",
              fieldName: "License Plate",
              maxVal: 15,
              minVal: 5,
            );
          },
        ),
        const SizedBox(height: 15),
        CustomFormField(
          controller: controller.drivingLicenseController,
          hintText: "DL-987654321",
          labelText: "Driving License Number",
          fieldIcon: const Icon(Icons.badge, size: 25),
          validator: (val) {
            return validFields(
              val: val!,
              type: "text",
              fieldName: "Driving License",
              maxVal: 20,
              minVal: 8,
            );
          },
        ),
      ],
    );
  }

  Widget _signUpPageActions(
      {required void Function() signUpFunction,
      required SignupController controller}) {
    return Column(
      spacing: ScreenSize.screenWidth! * 0.08,
      children: [
        SizedBox(height: ScreenSize.screenHeight! * 0.02),
        Obx(() {
          if (controller.requestState.value == RequestState.loading) {
            return CircularProgressIndicator(color: AppColors.blueColor);
          }
          return CustomBtn(
            btnColor: AppColors.blueColor,
            btnFunc: signUpFunction,
            textColor: Colors.white,
            text: "Sign Up",
          );
        }),
        SizedBox(height: ScreenSize.screenHeight! * 0.025),
        Center(
          child: InkWell(
            onTap: controller.goToLoginScreen,
            child: RichText(
              text: TextSpan(
                text: "Already have an account? ",
                style: TextStyle(fontSize: 16, color: AppColors.blueColor),
                children: [
                  TextSpan(
                    text: "Login",
                    style: TextStyle(fontSize: 16, color: AppColors.blueColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}