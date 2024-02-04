import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/appinfo/app_info.dart';
import 'package:uber_clone_user_app/authentification/login_screen.dart';
import 'package:uber_clone_user_app/pages/home_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if(valueOfPermission){
      Permission.locationWhenInUse.request();
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=>AppInfo(),
      child: MaterialApp(
        title: 'Flutter User App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            buttonTheme: ButtonThemeData()),
        home:FirebaseAuth.instance.currentUser==null? LoginScreen()
        :HomePage(),
      ),
    );
  }
}
