import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone_user_app/global/global_var.dart';
import 'package:uber_clone_user_app/methods/common_methods.dart';
import 'package:uber_clone_user_app/pages/search_destination_page.dart';

import '../authentification/login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey=GlobalKey<ScaffoldState>();
  CommonMethods cMethods=CommonMethods();
  double searchContainerHeight=276;
  double bottomMapPadding=0;

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes('themes/night_style.json')
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  getCurrentLiveLocationOfUser() async {
    Position positionUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionUser;
    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    await CommonMethods.convertGeoGraphicCoordinatesIntoHumanReadableAddress(currentPositionOfUser!, context);
    await getUserAndCheckBlockStatus();
  }

  getUserAndCheckBlockStatus()async{
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid);
    await usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)['blockStatus'] == 'no') {
          setState(() {
            userName=(snap.snapshot.value as Map)['name'];
          });
        } else {
          FirebaseAuth.instance.signOut();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => LoginScreen()),
          );
          cMethods.displaySnackBar(
              'your are blocked. Contact admin: prostreet1212@gmail.com',
              context);
        }
      } else {
        FirebaseAuth.instance.signOut();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => LoginScreen()),
        );

      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [
              Divider(height: 1,color: Colors.grey,
                thickness: 1,),
              //header
              Container(
                color: Colors.black54,
                height: 160,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                  ),
                  child: Row(
                    children: [

                   Image.asset('assets/images/avatarman.png',
                   width: 60,
                       height: 60,),
                      SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(userName,
                        style: TextStyle(
                          fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold
                        ),
                          ),
                          SizedBox(height: 4,),
                          Text('Profile',
                            style: TextStyle(
                                color: Colors.white38,
                            ),
                          ),

                        ],
                      )
                    ],
                  ),
                ),
              ),
              Divider(height: 1,color: Colors.grey,
              thickness: 1,),
              SizedBox(height: 10,),
              //body
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.info,color: Colors.grey,),
                  onPressed: (){},
                ),
                title: Text('About',style:TextStyle(color: Colors.grey) ,),
              ),
              GestureDetector(
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.logout,color: Colors.grey,),
                    onPressed: (){},
                  ),
                  title: Text('Logout',style:TextStyle(color: Colors.grey) ,),
                ),
                onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: EdgeInsets.only(top: 26,bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);
              getCurrentLiveLocationOfUser();
              setState(() {
                bottomMapPadding=300;
              });
            },
          ),
          //drawer button
          Positioned(
            top: 36,
              left: 19,
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7)
                      )
                    ]
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 20,
                    child: Icon(Icons.menu,color: Colors.black87,
                    ),
                  ),
                ),
                onTap: (){
                  sKey.currentState!.openDrawer();
                },
              ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding:EdgeInsets.all(24),
                    ),
                    child: Icon(Icons.search,color: Colors.white,
                    size: 25,),
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (c)=>SearchDestinationPage()));
                    }, ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding:EdgeInsets.all(24),
                    ),
                    child: Icon(Icons.home,
                      color: Colors.white,
                      size: 25,),
                    onPressed: (){}, ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding:EdgeInsets.all(24),
                    ),
                    child: Icon(Icons.work,color: Colors.white,
                      size: 25,),
                    onPressed: (){}, ),

                ],
              ),

            ),
          )
        ],
      ),
    );
  }
}
