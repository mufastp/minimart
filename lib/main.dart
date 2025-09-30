import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'App_Routes.dart';
import 'DependencyInjection.dart';
int? windowId; // To hold the window ID for sub-windows
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize GetStorage and dependencies in main window
  if (args.isEmpty) {
    await GetStorage.init();
    DependencyInjection.init();
  }

  // Decode window arguments safely for sub-windows
  Map<String, dynamic> windowArgs = {};
  if (args.isNotEmpty) {
    try {
      windowArgs = jsonDecode(args.first) as Map<String, dynamic>;
    } catch (e) {
      print("Failed to decode window args: $e");
    }
  }

  final box = GetStorage();
  final bool isLoggedIn = box.read('isLoggedIn') ?? false;

  runApp(MyApp(
    initialRoute: args.isEmpty
        ? (isLoggedIn ? AppRoutes.initial : AppRoutes.login)
        : (windowArgs['route'] ?? '/newwindow'), // Sub-window route from args
    windowTitle: windowArgs['title'] ??
        (args.isEmpty ? "Main Window" : "Selected Products - New Window"),
    isSubWindow: args.isNotEmpty,
    autoOpenNewWindow: args.isEmpty, // Only auto-open for main window
  ));
}

  Future<void> openNewWindow() async {
    try {
      final window = await DesktopMultiWindow.createWindow(
        jsonEncode({"title": "Selected Products", "route": "/newwindow"}),
      );
      window
        ..setFrame(const Offset(200, 200) & const Size(800, 1280))
        ..setTitle("Selected Products - New Window")
        ..show();
        windowId=window.windowId;

      print("Auto-opened new window successfully");
    } catch (e) {
      print("Error auto-opening new window: $e");
    }
  }

class MyApp extends StatefulWidget {
  final String initialRoute;
  final String windowTitle;
  final bool isSubWindow;
  final bool autoOpenNewWindow;

  const MyApp({
    super.key,
    required this.initialRoute,
    this.windowTitle = "Window",
    this.isSubWindow = false,
    this.autoOpenNewWindow = false,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (widget.autoOpenNewWindow) {
      // Auto-open new window after a short delay to ensure app is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        openNewWindow();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(800, 1280),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return GetMaterialApp(
          title: widget.windowTitle,
          debugShowCheckedModeBanner: false,
          initialRoute:
              widget.isSubWindow ? widget.initialRoute : widget.initialRoute,
          getPages: AppRoutes.routes,
          navigatorObservers: [GetObserver()],
        );
      },
    );
  }
}
