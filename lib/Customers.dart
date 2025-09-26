import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart'as http;
import 'package:minimart/Details.dart';
class CustomerController extends GetxController {
  RxList<Customerss> customers = <Customerss>[].obs;
  Rx<Customerss?> selectedCustomer = Rx<Customerss?>(null);
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    fetchCustomers();
    super.onInit();
  }

  void fetchCustomers() async {
    try {
      isLoading(true);

      final response = await http.get(
        Uri.parse('http://68.183.92.8:3699/api/get_customer?store_id=${Details.storeId}'),
      );
      if (response.statusCode == 200) {
        print(response.request);
        final json = jsonDecode(response.body);
        customers.value = List<Customerss>.from(
          json['data'].map((x) => Customerss.fromJson(x)),
        );
      } else {
        Get.snackbar('Error', 'Server Error: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading(false);
    }
  }
}



class Customerss {
  final int id;
  final String name;
  final String code;

  Customerss({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Customerss.fromJson(Map<String, dynamic> json) {
    return Customerss(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      code: json['code'] ?? '',
    );
  }

  @override
  String toString() => "$name ($code)";
}


