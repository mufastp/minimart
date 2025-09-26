import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:minimart/Details.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  static const Color colorPrimary = Colors.deepPurpleAccent;
  static const Color backgroundColor = Colors.white;
  static const double headLineSize = 20.0;
  static const FontWeight headLineWeight = FontWeight.bold;
}

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }
}


class CommonWidgets {
  static Widget verticalSpace(double height) =>
      SizedBox(height: SizeConfig.blockSizeVertical * height);

  static void showDialogueBox({
    required BuildContext context,
    required String title,
    required String msg,
  }) {
    Get.dialog(AlertDialog(title: Text(title), content: Text(msg)));
  }

  static Widget button({
    required VoidCallback function,
    required double height,
    required double width,
    required double radius,
    required String title,
    required Color bgColor,
    required Color textColor,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: function,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Text(title, style: TextStyle(color: textColor)),
      ),
    );
  }
}

// === LOGIN CONTROLLER ===
class LoginController extends GetxController {
  var isLoading = false.obs;
  var obscurePassword = true.obs;

  Future<void> login(String email, String password) async {
    isLoading.value = true;

    final url = Uri.parse("http://68.183.92.8:3699/api/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final box = GetStorage();
        final data = jsonDecode(response.body);
        final user = data['user'];
        final userId = user['id'];
        final userName = user['name'];
        final storeId = user['store_id'];

        box.write('isLoggedIn', true);
        box.write('userId', userId);
        box.write('userName', userName);
        box.write('storeId', storeId);

        // Fetch store details after successful login
        await fetchStoreDetails(storeId.toString(), box);

        Get.snackbar("Login Success", "Welcome back!");
        print(Details.userId);
        print(Details.storeId);
        Get.offAllNamed('/');
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar("Login Failed", error['message'] ?? "Invalid credentials");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStoreDetails(String storeId, GetStorage box) async {
    try {
      final storeUrl = Uri.parse("http://68.183.92.8:3699/api/get_store_detail?store_id=$storeId");
      final response = await http.get(storeUrl);

      if (response.statusCode == 200) {
        print(response.request);
        final storeData = jsonDecode(response.body);
        if (storeData['success'] == true) {
          final storeDetails = storeData['data'];
          final currency = storeDetails['currency'];
          final round_off = storeDetails['round_off'];
          box.write('round_off', round_off);

          // Store the currency in GetStorage
          box.write('currency', currency);
          print('Currency stored: $currency');
        }
      } else {
        print('Failed to fetch store details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching store details: $e');
    }
  }

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '1.0.4+1';
  }

}

// === LOGIN PAGE ===
class LoginPage extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: const Color(0xffFFFBFF),
      body: SingleChildScrollView(
        child: SizedBox(
          height: SizeConfig.screenHeight,
          child: Stack(
            children: [
              Container(
                height: SizeConfig.blockSizeVertical * 45,
                decoration: BoxDecoration(
                  color: AppConfig.colorPrimary,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.elliptical(
                      MediaQuery.of(context).size.width,
                      160.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: SizeConfig.blockSizeVertical * 13,
                left: 18,
                child: Text(
                  'Mobiz',
                  style: TextStyle(
                    fontSize: AppConfig.headLineSize * 2,
                    color: AppConfig.backgroundColor,
                    fontWeight: AppConfig.headLineWeight,
                  ),
                ),
              ),
              Positioned(
                top: SizeConfig.blockSizeVertical * 18,
                left: 18,
                child: Text(
                  'POS',
                  style: TextStyle(
                    fontSize: AppConfig.headLineSize * 1.5,
                    color: AppConfig.backgroundColor,
                  ),
                ),
              ),
              Positioned(
                top: SizeConfig.blockSizeVertical * 30,
                left: SizeConfig.blockSizeHorizontal * 35,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    width: SizeConfig.blockSizeHorizontal * 30,
                    decoration: const BoxDecoration(
                      color: AppConfig.backgroundColor,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonWidgets.verticalSpace(2),
                        Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: AppConfig.headLineSize * 1.2,
                            fontWeight: AppConfig.headLineWeight,
                          ),
                        ),
                        const Text('Please sign in with your details'),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.person),
                            border: _inputBorder(),
                            enabledBorder: _inputBorder(),
                            focusedBorder: _focusBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(() => TextField(
                          controller: passwordController,
                          obscureText: controller.obscurePassword.value,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: _inputBorder(),
                            enabledBorder: _inputBorder(),
                            focusedBorder: _focusBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(controller.obscurePassword.value
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                controller.obscurePassword.value =
                                !controller.obscurePassword.value;
                              },
                            ),
                          ),
                        )),
                        CommonWidgets.verticalSpace(5),
                        Center(
                          child: Obx(() => controller.isLoading.value
                              ? const CircularProgressIndicator()
                              : CommonWidgets.button(
                            bgColor: AppConfig.colorPrimary,
                            textColor: AppConfig.backgroundColor,
                            function: () {
                              if (emailController.text.isEmpty) {
                                CommonWidgets.showDialogueBox(
                                    context: context,
                                    title: 'Error',
                                    msg: "Please enter a valid email");
                              } else if (passwordController.text.isEmpty) {
                                CommonWidgets.showDialogueBox(
                                    context: context,
                                    title: 'Error',
                                    msg: "Please enter a valid password");
                              } else {
                                controller.login(
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                );
                              }
                            },
                            height: SizeConfig.blockSizeVertical * 7,
                            width: SizeConfig.blockSizeHorizontal * 67,
                            radius: 10,
                            title: 'Log In',
                          )),
                        ),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: FutureBuilder<String>(
                              future: controller._getAppVersion(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(); // You can also show a loader here
                                } else if (snapshot.hasError) {
                                  return const Text("Error loading version");
                                } else {
                                  return Text(
                                    "Version: ${snapshot.data}",
                                    style: TextStyle(fontSize: 8.sp, color: Colors.grey, fontWeight: FontWeight.bold));                              }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder() => const OutlineInputBorder(
    borderSide: BorderSide(color: AppConfig.colorPrimary),
  );

  OutlineInputBorder _focusBorder() => const OutlineInputBorder(
    borderSide: BorderSide(color: AppConfig.colorPrimary, width: 2.0),
  );
}
