import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'App_Routes.dart';
import 'DependencyInjection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  DependencyInjection.init();
  final box = GetStorage();
  final bool isLoggedIn = box.read('isLoggedIn') ?? false;
  runApp(MyApp(initialRoute: isLoggedIn ? AppRoutes.initial : AppRoutes.login));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(800, 1280),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return GetMaterialApp(
          title: 'Supermarket POS',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          getPages: AppRoutes.routes,
          navigatorObservers: [GetObserver()],
        );
      },
    );
  }
}
