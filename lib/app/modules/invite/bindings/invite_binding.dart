import 'package:get/get.dart';
import '../controllers/invite_controller.dart';

class InviteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InviteController>(() => InviteController());
  }
}
