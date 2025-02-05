import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hr_app/homepage.dart';
import 'package:hr_app/login.dart';

void main() async {
  // Initialize Hive and make sure it's ready before running the app
  await Hive.initFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRMS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/', // Initial route when the app starts
      onGenerateRoute: (settings) {
        // Handle route generation dynamically
        switch (settings.name) {
          case '/admin_dashboard':
            return MaterialPageRoute(
              builder: (context) => HRDashboard(),
            );
          case '/user_dashboard':
            return MaterialPageRoute(
              builder: (context) => HRDashboard(),
            );
          case '/manager_dashboard':
            return MaterialPageRoute(
              builder: (context) => HRDashboard(// Pass actual user data
                  ),
            );
          default:
            // Default route if none of the above match
            return MaterialPageRoute(builder: (context) => LoginScreen());
        }
      },
    );
  }
}
