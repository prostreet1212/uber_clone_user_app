import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../appinfo/app_info.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({Key? key}) : super(key: key);

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {

    String userAddress=Provider.of<AppInfo>(context,listen: false).pickUpLocation!.humanReadableAddress??'';
    pickUpTextEditingController.text=userAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                height: 230,
                decoration: BoxDecoration(color: Colors.black12, boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7))
                ]),
                child: Padding(
                  padding:
                      EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 6,
                      ),
                      //icon button-title
                      Stack(
                        children: [
                          GestureDetector(
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          Center(
                            child: Text(
                              'Set Dropoff Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 18,
                      ),
                      //pickup text field
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/initial.png',
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(
                            width: 18,
                          ),
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: TextField(
                                controller: pickUpTextEditingController,
                                decoration: InputDecoration(
                                  hintText: 'Pickup Address',
                                  fillColor: Colors.white12,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(left: 11,top: 9,bottom: 9)
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                      SizedBox(
                        height: 11,
                      ),
                      //destination text field
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/final.png',
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(
                            width: 18,
                          ),
                          Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(3),
                                  child: TextField(
                                    controller: destinationTextEditingController,
                                    decoration: InputDecoration(
                                        hintText: 'Destination Address',
                                        fillColor: Colors.white12,
                                        filled: true,
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.only(left: 11,top: 9,bottom: 9)
                                    ),
                                  ),
                                ),
                              ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
