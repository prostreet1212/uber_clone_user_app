import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone_user_app/authentification/login_screen.dart';
import 'package:uber_clone_user_app/methods/common_methods.dart';
import 'package:uber_clone_user_app/widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController =
      TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  checkIfNetworkIsAvailable() async {
    await cMethods.checkConnectivity(context);
    signUpFormValidation();
  }

  signUpFormValidation() {
    if (userNameTextEditingController.text.trim().length <= 3) {
      cMethods.displaySnackBar(
          'your name must be atleast 4 or more characters', context);
    } else if (userPhoneTextEditingController.text.trim().length <= 7) {
      cMethods.displaySnackBar(
          'your phone must be atleast 8 or more characters', context);
    } else if (!emailTextEditingController.text.contains('@')) {
      cMethods.displaySnackBar('please write valid email', context);
    } else if (passwordTextEditingController.text.trim().length < 5) {
      cMethods.displaySnackBar(
          'your password must be atleast 8 or more characters', context);
    } else {
      //register user
      registerNewUser();
    }
  }

  registerNewUser() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) =>
          LoadingDialog(messageText: 'Registering your account...'),
    );
    final User? userFirebase = (await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
      email: emailTextEditingController.text.trim(),
      password: passwordTextEditingController.text.trim(),
    )
            .catchError((errorMsg) {
      Navigator.pop(context);
      cMethods.displaySnackBar(errorMsg.toString(), context);
    }))
        .user;
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png'),
              Text(
                'Create a User\'s Account ',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              //text fields and button
              Padding(
                padding: const EdgeInsets.only(
                  right: 22,
                  left: 22,
                  top: 22,
                  bottom: 14,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: userNameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: 'User Name',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'User Name',
                          hintStyle: TextStyle()),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: userPhoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'User Phone',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'User Phone',
                          hintStyle: TextStyle()),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'User Email',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'User Email',
                          hintStyle: TextStyle()),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: 'User Password',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'User Password',
                          hintStyle: TextStyle()),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 10)),
                      child: const Text('Sign Up'),
                      onPressed: () {
                        checkIfNetworkIsAvailable();
                      },
                    )
                  ],
                ),
              ),

              //login? button
              TextButton(
                child: const Text(
                  'Already have an Account? Login Where',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => LoginScreen()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
