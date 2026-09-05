import 'package:get/get.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import '../controllers/workspace_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(WorkspaceController());
    Get.lazyPut<RequestBuilderController>(() => RequestBuilderController());
  }
}
