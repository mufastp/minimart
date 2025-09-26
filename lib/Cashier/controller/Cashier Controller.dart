import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CashierController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 1, vsync: this);
    tabController.addListener(() {
      selectedIndex.value = tabController.index + 1;
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
