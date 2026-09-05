import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';
import '../controllers/socket_controller.dart';

class RequestBuilderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RequestBuilderController>(() => RequestBuilderController());
    Get.lazyPut<SocketController>(() => SocketController());
  }
}
