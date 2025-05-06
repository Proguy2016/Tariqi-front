import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/field_valid.dart';
import 'package:tariqi/const/functions/pop_func.dart';
import 'package:tariqi/controller/auth_controllers/login_controller.dart';
import 'package:tariqi/view/core_widgets/custom_btn.dart';
import 'package:tariqi/view/core_widgets/custom_form_field.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/core_widgets/pop_widget.dart';
import 'package:tariqi/const/class/request_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(LoginController());
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
                      key: controller.formKey,
                      child: Column(
                        spacing: ScreenSize.screenWidth! * 0.15,
                        children: [
                          _loginPageHeader(),
                          _buildLoginInputs(controller: controller),
                          _loginPageActions(
                            loginFunction: () => controller.loginFunc(),
                            googleLogin: () {
                              // Handle Google Login Function
                            },
                            Controller: LoginController(),
                            loading: RequestState.loading,
                            goToSignUpFunction:
                                () => controller.goToSignUpPage(),
                          ),
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

  Widget _loginPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome",
          style: TextStyle(
            fontSize: 30,
            color: AppColors.blueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "To find your pickup location automatically,\nplease turn on location services after Login",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginInputs({required LoginController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ScreenSize.screenWidth! * 0.04,
      children: [
        Column(
          spacing: ScreenSize.screenWidth! * 0.1,
          children: [
            CustomFormField(
              validator: (val) {
                return validFields(
                  val: val!,
                  type: "email",
                  fieldName: "Email",
                  maxVal: 100,
                  minVal: 10,
                );
              },
              controller: controller.emailController,
              hintText: "Enter Your Email",
              labelText: "Email",
              fieldIcon: Icon(Icons.alternate_email, size: 25),
            ),
            GetBuilder<LoginController>(
              builder:
                  (controller) => CustomFormField(
                    secureText: controller.showPassword.value,
                    validator: (val) {
                      return validFields(
                        val: val!,
                        type: "password",
                        fieldName: "Password",
                        maxVal: 30,
                        minVal: 6,
                      );
                    },
                    controller: controller.passwordController,
                    hintText: "Enter Your Password",
                    labelText: "Password",
                    fieldIcon: IconButton(
                      onPressed: () {
                        controller.toggleShowPass();
                      },
                      icon:
                          controller.showPassword.value
                              ? Icon(Icons.visibility_off_outlined, size: 25)
                              : Icon(Icons.visibility_outlined, size: 25),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loginPageActions({
    required void Function()? googleLogin,
    required void Function() loginFunction,
    required void Function() goToSignUpFunction, 
    required LoginController Controller,
    required loading,
  }) {
    return Column(
      spacing: ScreenSize.screenWidth! * 0.08,
      children: [
        Obx(() {
  if (Controller.requestState.value == loading) {
    return CircularProgressIndicator(color: AppColors.blueColor);
  }
  return CustomBtn(
    btnColor: AppColors.blueColor,
    btnFunc: loginFunction,
    textColor: Colors.white,
    text: "Login",
  );
}),
        SizedBox(height: ScreenSize.screenHeight! * 0.025),
        Center(
          child: InkWell(
            onTap: goToSignUpFunction,
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(fontSize: 16, color: AppColors.blueColor),
                children: [
                  TextSpan(
                    text: "Sign Up",
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
