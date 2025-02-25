import 'package:driveorbit_app/screen/dashboard/dashboard_driver_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(449, 973),
      child: const MaterialApp(
        home: DashboardDriverPage(),
      ),
    );
  }
}
