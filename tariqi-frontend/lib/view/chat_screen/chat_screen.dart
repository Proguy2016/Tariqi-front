import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/controller/chat_screen_controller/chat_screen_controller.dart';
import 'package:tariqi/view/chat_screen/widgets/chat_inputs.dart';
import 'package:tariqi/view/chat_screen/widgets/message_card.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatScreenController());
    return Scaffold(
      appBar: AppBar(title: Text("Chat Screen"), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => HandlingView(
                requestState: controller.requestState.value,
                widget: Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return SizedBox(
                        height: ScreenSize.screenHeight! * 0.01,
                      );
                    },
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      return buildMessageCard(
                        message: controller.messages[index]
                      );
                    },
                  ),
                ),
              ),
            ),
            chatInput(
              sendMessageFunc: () => controller.sendMessage(),
              messageFieldController: controller.messageFieldController,
              messageFormKey: controller.messageFormKey,
            ),
          ],
        ),
      ),
    );
  }
}
