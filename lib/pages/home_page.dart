import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/global/global_var.dart';
import 'package:uber_clone_user_app/methods/common_methods.dart';
import 'package:uber_clone_user_app/models/direction_details.dart';
import 'package:uber_clone_user_app/pages/search_destination_page.dart';

import '../appinfo/app_info.dart';
import '../authentification/login_screen.dart';
import '../widgets/loading_dialog.dart';



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
  GeoPoint? currentPositionOfUser1;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  MapController mapController = MapController.withUserPosition(
    trackUserLocation: UserTrackingOption(
      enableTracking: true,
      unFollowUser: true,
    ),
  );

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
    /*Position positionUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionUser;
    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));*/
    if (currentPositionOfUser1 != null) {
      await CommonMethods.convertGeoGraphicCoordinatesIntoHumanReadableAddress(
          currentPositionOfUser1!, context);
    }
    await getUserAndCheckBlockStatus();
  }

  getUserAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid);
    await usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)['blockStatus'] == 'no') {
          setState(() {
            userName = (snap.snapshot.value as Map)['name'];
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

  displayUserRideDetailsContainer() async {
    //draw route between pickup and dropoff
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 242;
    });
  }

  retrieveDirectionDetails() async {
    var pickupLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffUpLocation;

    var pickupGeoGraphicCoordinates = LatLng(
        pickupLocation!.latitudePosition!, pickupLocation!.longitudePosition!);
    var dropOffDestinationGeoGraphicCoordinates = LatLng(
        dropOffDestinationLocation!.latitudePosition!,
        dropOffDestinationLocation!.longitudePosition!);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) =>
            LoadingDialog(messageText: 'Getting direction...'));
    //directions API
    var detailsFromDirectionAPI =
        await CommonMethods.getDirectionDetailsFromAPI(
            pickupGeoGraphicCoordinates,
            dropOffDestinationGeoGraphicCoordinates,
        mapController);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });
    await mapController.addMarker(
        GeoPoint(
            latitude: pickupGeoGraphicCoordinates.latitude,
            longitude: pickupGeoGraphicCoordinates.longitude),
        markerIcon: const MarkerIcon(
          icon:Icon(CupertinoIcons.location_solid,size: 46,color: Colors.green,),),
        angle: pi / 3,
        iconAnchor: IconAnchor(
          anchor: Anchor.center,
        ));
    await mapController.addMarker(
        GeoPoint(
            latitude: dropOffDestinationGeoGraphicCoordinates.latitude,
            longitude: dropOffDestinationGeoGraphicCoordinates.longitude),
        markerIcon: const MarkerIcon(
          icon:Icon(CupertinoIcons.location_solid,size: 46,color: Colors.deepOrange,),),
        angle: pi / 3,
        iconAnchor: IconAnchor(
          anchor: Anchor.center,
        ));
    Navigator.pop(context);
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
              Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),
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
                      Image.asset(
                        'assets/images/avatarman.png',
                        width: 60,
                        height: 60,
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Profile',
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
              Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),
              SizedBox(
                height: 10,
              ),
              //body
              ListTile(
                leading: IconButton(
                  icon: Icon(
                    Icons.info,
                    color: Colors.grey,
                  ),
                  onPressed: () {},
                ),
                title: Text(
                  'About',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              GestureDetector(
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                onTap: () {
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
          /* GoogleMap(
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
          ),*/
          OSMFlutter(
            controller: mapController,
            osmOption: OSMOption(
              zoomOption: ZoomOption(
                initZoom: 12,
                /* minZoomLevel: 4,
          maxZoomLevel: 14,*/
                stepZoom: 1,
              ),
              /*userTrackingOption: UserTrackingOption(
          enableTracking: true,
          unFollowUser: true,
        ),*/
              userLocationMarker: UserLocationMaker(
                personMarker: MarkerIcon(
                  icon: Icon(
                    Icons.personal_injury,
                    color: Colors.black,
                    size: 48,
                  ),
                ),
                directionArrowMarker: MarkerIcon(
                  icon: Icon(
                    Icons.location_on,
                    color: Colors.black,
                    size: 48,
                  ),
                ),
              ),

              /*  markerOption: MarkerOption(
          defaultMarker: MarkerIcon(
            icon: Icon(
              Icons.person_pin_circle,
              color: Colors.black,
              size: 48,
            ),
          ),
        ),*/
              roadConfiguration: RoadOption(
                roadColor: Colors.deepOrange.withOpacity(0).withAlpha(0),
                roadBorderWidth: 1,
              ),
            ),
            onLocationChanged: (GeoPoint geo) {
              //currentPositionOfUser1 = geo;
              print('ИЗменить${geo.toString()}');
            },
            onMapIsReady: (isReady) async {
              if (isReady) {
                await Future.delayed(Duration(seconds: 1), () async {
                  await mapController.currentLocation();
                  currentPositionOfUser1=await mapController.myLocation();
                  getCurrentLiveLocationOfUser();
                });
              }
            },
            mapIsLoading: Center(child: CircularProgressIndicator()),
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
                          offset: Offset(0.7, 0.7))
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(
                    Icons.menu,
                    color: Colors.black87,
                  ),
                ),
              ),
              onTap: () {
                sKey.currentState!.openDrawer();
              },
            ),
          ),
          //search location icon button
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
                      padding: EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 25,
                    ),
                    onPressed: () async {
                      var responseFromSearchPage = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => SearchDestinationPage()));
                      if (responseFromSearchPage == 'placeSelected') {
                        String dropOffLocation =
                            Provider.of<AppInfo>(context, listen: false)
                                    .dropOffUpLocation!
                                    .placeName ??
                                '';
                        print('dropOffLocation =' + dropOffLocation);
                        displayUserRideDetailsContainer();
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 25,
                    ),
                    onPressed: () {},
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                    ),
                    child: Icon(
                      Icons.work,
                      color: Colors.white,
                      size: 25,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          // ride details container
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white12,
                        blurRadius: 15,
                        spreadRadius: 0.5,
                        offset: Offset(.7, .7),
                      )
                    ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: SizedBox(
                          height: 190,
                          child: Card(
                            elevation: 10,
                            child: Container(
                              width: MediaQuery.of(context).size.width * .7,
                              color: Colors.black45,
                              child: Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding:EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            (tripDirectionDetailsInfo != null)
                                                ? tripDirectionDetailsInfo!
                                                    .distanceTextString!
                                                : '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            (tripDirectionDetailsInfo != null)
                                                ? tripDirectionDetailsInfo!
                                                .durationTextString!
                                                : '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      child: Image.asset(
                                        'assets/images/uberexec.png',
                                        height: 116,
                                        width: 116,
                                      ),
                                      onTap: () {},
                                    ),
                                    Text(
                                      '\$ 12',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
