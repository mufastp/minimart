import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:minimart/Details.dart';

/// ---------------- CONTROLLER ----------------
class CustomerPageController extends GetxController {
  var isLoading = true.obs;
  var customers = <Customer>[].obs;
  var expandedIndex = (-1).obs;
  Future<void> fetchCustomers() async {
    try {
      isLoading(true);
      final url = Uri.parse(
          "http://68.183.92.8:3699/api/get_customer?store_id=${Details.storeId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse["success"] == true) {
          var data = jsonResponse["data"] as List;
          customers.value =
              data.map((item) => Customer.fromJson(item)).toList();
        } else {
          customers.clear();
        }
      } else {
        customers.clear();
      }
    } catch (e) {
      customers.clear();
    } finally {
      isLoading(false);
    }
  }

  void toggleExpansion(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = -1; // Collapse if already expanded
    } else {
      expandedIndex.value = index; // Expand selected tile
    }
  }

  @override
  void onInit() {
    fetchCustomers();
    super.onInit();
  }
}


class CustomerPage extends StatelessWidget {
  final CustomerPageController controller = Get.put(CustomerPageController());

  CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Customer Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.customers.isEmpty) {
          return const Center(
            child: Text(
              "No Customers Found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.customers.length,
          itemBuilder: (context, index) {
            final customer = controller.customers[index];

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.deepPurple.shade50,
                collapsedBackgroundColor: Colors.white,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                title: Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.edit,
                  color: Colors.deepPurple,
                  size: 28,
                ),

                // Expanded Details
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        buildInfoRow("Code", customer.code),
                        buildInfoRow("Contact", customer.contactNumber),
                        buildInfoRow("Email", customer.email),
                        buildInfoRow("Payment Terms", customer.paymentTerms),
                        buildInfoRow("Credit Limit", "${customer.creditLimit}"),
                        buildInfoRow("Credit Days", "${customer.creditDays}"),
                        buildInfoRow("Route ID", "${customer.routeId}"),
                        buildInfoRow("Province ID", "${customer.provinceId}"),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- MODEL ----------------
class Customer {
  final int id;
  final String name;
  final String code;
  final String? address;
  final String? building;
  final String? flatNo;
  final String contactNumber;
  final String? whatsappNumber;
  final String email;
  final String? trn;
  final String? custImage;
  final String paymentTerms;
  final int creditLimit;
  final int creditDays;
  final String? location;
  final int routeId;
  final int provinceId;
  final int storeId;
  final int status;

  Customer({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.building,
    this.flatNo,
    required this.contactNumber,
    this.whatsappNumber,
    required this.email,
    this.trn,
    this.custImage,
    required this.paymentTerms,
    required this.creditLimit,
    required this.creditDays,
    this.location,
    required this.routeId,
    required this.provinceId,
    required this.storeId,
    required this.status,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      address: json['address'],
      building: json['Building'],
      flatNo: json['Flat_no'],
      contactNumber: json['contact_number'] ?? '',
      whatsappNumber: json['whatsapp_number'],
      email: json['email'] ?? '',
      trn: json['trn'],
      custImage: json['cust_image'],
      paymentTerms: json['payment_terms'] ?? '',
      creditLimit: json['credit_limit'] ?? 0,
      creditDays: json['credit_days'] ?? 0,
      location: json['location'],
      routeId: json['route_id'] ?? 0,
      provinceId: json['province_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      status: json['status'] ?? 0,
    );
  }
}
