import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:minimart/Details.dart';
import 'package:minimart/main.dart';
import 'ProductSearch.dart';
import 'SelectedProductsWidget.dart';

class HomePage extends StatelessWidget {
  final productSearchController = Get.put(ProductSearchController());
  final cartController = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Products',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.deepPurpleAccent,
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                focusNode: productSearchController.searchFocusNode,
                controller: productSearchController.searchController,
                autofocus: true,
                onChanged: (value) {
                  productSearchController.searchProducts(value);
                },
                onSubmitted: (value) {
                  productSearchController.searchProducts(
                    value,
                    isScanned: true,
                    searchFocusNode: productSearchController.searchFocusNode,
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (productSearchController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productSearchController.searchController.text.isNotEmpty &&
                    productSearchController.products.isNotEmpty) {
                  return ListView.builder(
                    itemCount: productSearchController.products.length,
                    itemBuilder: (context, index) {
                      final product = productSearchController.products[index];
                      return ListTile(
                        leading: const Icon(Icons.shopping_bag),
                        title: Text(product.productName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Rate: ${Details.currency}${(product.price).toStringAsFixed(2)}'),
                            Text('Unit: ${product.unitName}'),
                          ],
                        ),
                        onTap: () {
                          cartController.addToCart(product);
                          Get.snackbar(
                            'Added',
                            '${product.productName} added to cart',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          productSearchController.searchController.clear();
                          productSearchController.products.clear();
                        },
                      );
                    },
                  );
                }

                if (cartController.cartItems.isNotEmpty) {
                  return SelectedProductsWidget(
                      newwindow: false,
                      cartController: cartController,
                      currencySymbol: Details.currency ?? "");
                }

                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Search for products to add to cart',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // Updated total section with discount calculation
            // Updated total section with discount calculation
            Obx(() {
              if (cartController.cartItems.isEmpty)
                return const SizedBox.shrink();

              return Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Sub Total: (${cartController.cartItems.length} Item${cartController.cartItems.length > 1 ? 's' : ''})"),
                            Text("Total Discount: "),
                            Text("VAT: "),
                            Text("Total: ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                "${Details.currency}${cartController.subtotal.toStringAsFixed(2)}"),
                            Text(
                                "${Details.currency}${cartController.totalDiscount.toStringAsFixed(2)}",
                                style: TextStyle(color: Colors.red)),
                            Text(
                                "${Details.currency}${cartController.totalTax.toStringAsFixed(2)}"),
                            Text(
                                "${Details.currency}${cartController.grandTotal.toStringAsFixed(2)}",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(200.w, 100.h),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () {
                        print("Check");
                        Get.snackbar('Checkout', 'Proceeding to payment...');
                        final args = {
                          "cartItems": cartController.cartItems
                              .map((e) => e.toJson())
                              .toList(),
                          "subtotal": cartController.subtotal,
                          "totalDiscount": cartController.totalDiscount,
                          "totalTax": cartController.totalTax,
                          "grandTotal": cartController.grandTotal,
                          "currency": Details.currency
                        };
                        Get.toNamed('/checkout', id: 1, arguments: args);
                     gotoCheckout(arguments: jsonEncode(args));
                      },
                      child: Text(
                        'Checkout (${Details.currency}${cartController.grandTotal.toStringAsFixed(2)})',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ));
  }
}

void gotoCheckout({
  bool needOpen = false,
  String arguments = '',
}) async {
  if (windowId != null) {
    DesktopMultiWindow.invokeMethod(
      windowId!,
      "go_to_checkout",
      arguments,
    );
  } else {}
}
