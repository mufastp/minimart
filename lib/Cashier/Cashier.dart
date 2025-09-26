import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../Details.dart';
import 'Tabs/CashDrawer.dart';
import 'controller/Cashier Controller.dart';

class Cashier extends StatelessWidget {
  Cashier({super.key});

  final CashierController cashierController = Get.put(CashierController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${Details.userName![0].toUpperCase()}${Details.userName!.substring(1)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: CashDrawer(), // Directly show CashDrawer without tabs
      ),
    );
  }
}