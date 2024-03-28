import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:uber_clone_user_app/global/global_var.dart';
import 'package:uber_clone_user_app/global/trip_var.dart';
import 'package:uber_clone_user_app/methods/common_methods.dart';
import 'package:uber_clone_user_app/methods/manage_driver_methods.dart';
import 'package:uber_clone_user_app/methods/push_notification_service.dart';
import 'package:uber_clone_user_app/models/direction_details.dart';
import 'package:uber_clone_user_app/models/online_nearby_drivers.dart';
import 'package:uber_clone_user_app/pages/about_page.dart';
import 'package:uber_clone_user_app/pages/search_destination_page.dart';
import 'package:uber_clone_user_app/pages/trips_history_page.dart';
import 'package:uber_clone_user_app/widgets/info_dialog.dart';
import 'package:uber_clone_user_app/widgets/payment_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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

  //Position? currentPositionOfUser;
  GeoPoint? currentPositionOfUser1;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  MapController mapController = MapController.withUserPosition(
    trackUserLocation: UserTrackingOption(
      enableTracking: true,
      unFollowUser: true,
    ),
  );
  bool isDrawerOpened = true;
  String stateOfApp = 'normal';
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;

  makeDriverNearbyIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
              configuration, 'assets/images/tracking.png')
          .then((iconImage) {
        carIconNearbyDriver = iconImage;
      });
    }
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
    await initializeGeoFireListener();
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
            userPhone = (snap.snapshot.value as Map)['phone'];
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
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async {
    var pickupLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

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
            dropOffDestinationGeoGraphicCoordinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });
    await mapController.addMarker(
        GeoPoint(
            latitude: pickupGeoGraphicCoordinates.latitude,
            longitude: pickupGeoGraphicCoordinates.longitude),
        markerIcon: const MarkerIcon(
          icon: Icon(
            CupertinoIcons.location_solid,
            size: 46,
            color: Colors.green,
          ),
        ),
        angle: pi / 3,
        iconAnchor: IconAnchor(
          anchor: Anchor.center,
        ));
    await mapController.addMarker(
        GeoPoint(
            latitude: dropOffDestinationGeoGraphicCoordinates.latitude,
            longitude: dropOffDestinationGeoGraphicCoordinates.longitude),
        markerIcon: const MarkerIcon(
          icon: Icon(
            CupertinoIcons.location_solid,
            size: 46,
            color: Colors.deepOrange,
          ),
        ),
        angle: pi / 3,
        iconAnchor: IconAnchor(
          anchor: Anchor.center,
        ));
    RoadInfo roadInfo = await mapController.drawRoad(
      GeoPoint(
          latitude: pickupGeoGraphicCoordinates.latitude,
          longitude: pickupGeoGraphicCoordinates.longitude),
      GeoPoint(
          latitude: dropOffDestinationGeoGraphicCoordinates.latitude,
          longitude: dropOffDestinationGeoGraphicCoordinates.longitude),
      roadType: RoadType.car,
    );
    Navigator.pop(context);
  }

  resetAppNow() async {
    var pickupLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    var pickupGeoGraphicCoordinates = LatLng(
        pickupLocation!.latitudePosition!, pickupLocation!.longitudePosition!);
    var dropOffDestinationGeoGraphicCoordinates = LatLng(
        dropOffDestinationLocation!.latitudePosition!,
        dropOffDestinationLocation!.longitudePosition!);
    await mapController.clearAllRoads();
    await mapController.removeMarkers([
      GeoPoint(
          latitude: pickupGeoGraphicCoordinates.latitude,
          longitude: pickupGeoGraphicCoordinates.longitude),
      GeoPoint(
          latitude: dropOffDestinationGeoGraphicCoordinates.latitude,
          longitude: dropOffDestinationGeoGraphicCoordinates.longitude),
    ]);
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      status = '';
      nameDriver = '';
      photoDriver = '';
      phoneNumberDriver = '';
      carDetailsDriver = '';
      tripStatusDisplay = 'Driver is Arriving';
    });
    //Restart.restartApp();
  }

  cancelRideRequest() {
    //remove ride request from database
    tripRequestRef!.remove();
    setState(() {
      stateOfApp = 'normal';
    });
  }

  displayRequestContainer() {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });
    //send ride request
    makeTripRequest();
  }

  makeTripRequest() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child('tripRequests').push();
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickUpCoordinatesMap = {
      'latitude': pickUpLocation!.latitudePosition.toString(),
      'longitude': pickUpLocation!.longitudePosition.toString(),
    };
    Map dropOffDestinationCoordinatesMap = {
      'latitude': dropOffDestinationLocation!.latitudePosition.toString(),
      'longitude': dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoordinates = {
      'latitude': '',
      'longitude': '',
    };

    Map dataMap = {
      'tripID': tripRequestRef!.key,
      'psublishDateTime': DateTime.now().toString(),
      'userName': userName,
      'userPhone': userPhone,
      'userID': userID,
      'pickUpLatLng': pickUpCoordinatesMap,
      'dropOffLatLng': dropOffDestinationCoordinatesMap,
      'pickUpAddress': pickUpLocation.placeName,
      'dropOffAddress': dropOffDestinationLocation.placeName,
      'driverID': 'waiting',
      'carDetails': '',
      'driverLocation': driverCoordinates,
      'driverName': '',
      'driverPhone': '',
      'driverPhoto': '',
      'fareAmount': '',
      'status': 'new'
    };

    tripRequestRef!.set(dataMap);

    tripStreamSubscription = tripRequestRef!.onValue.listen((eventSnapshot)async {
      if (eventSnapshot.snapshot.value == null) {
        return;
      }
      if ((eventSnapshot.snapshot.value as Map)['driverName'] != null) {
        nameDriver = (eventSnapshot.snapshot.value as Map)['driverName'];
      }
      if ((eventSnapshot.snapshot.value as Map)["driverPhone"] != null) {
        phoneNumberDriver =
            (eventSnapshot.snapshot.value as Map)["driverPhone"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null) {
        photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
      }

      if ((eventSnapshot.snapshot.value as Map)["carDetails"] != null) {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }

      if ((eventSnapshot.snapshot.value as Map)["status"] != null) {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverLocation"] != null&&(eventSnapshot.snapshot.value as Map)["driverLocation"]['latitude'] != '') {
        double driverLatitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverLongitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());
        LatLng driverCurrentLocationLatLng =
            LatLng(driverLatitude, driverLongitude);
        if (status == "accepted") {
          //update info for pickup to user on UI
          //info from driver current location to user pickup location
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        } else if (status == "arrived") {
          //update info for arrived - when driver reach at the pickup point of user
          setState(() {
            tripStatusDisplay = 'Driver has Arrived';
          });
        } else if (status == "ontrip") {
          //update info for dropoff to user on UI
          //info from driver current location to user dropoff location
          updateFromDriverCurrentLocationToDropOffDestination(
              driverCurrentLocationLatLng);
        }
      }

      if (status == 'accepted') {
        displayTripRequestContainer();
        Geofire.stopListener();
        setState(() {
          //удалить маркеры других водил
         ManageDriverMethods.nearbyOnlineDriversList.forEach((geo) async {
            await mapController.removeMarker(
                GeoPoint(latitude: geo.latDriver!, longitude: geo.lngDriver!));
          });
          ManageDriverMethods.nearbyOnlineDriversList = []; //???
        });
      }
      if (status == 'ended') {
        if ((eventSnapshot.snapshot.value as Map)["fareAmount"] != null) {
          double fareAmount = double.parse(
              (eventSnapshot.snapshot.value as Map)["fareAmount"].toString());
         var responseFromPaymentDialog= await showDialog(
              context: context,
              builder: (context)=>PaymentDialog(fareAmount: fareAmount.toString()),
         );
         if(responseFromPaymentDialog=='paid'){
           tripRequestRef!.onDisconnect();
           tripRequestRef=null;
           tripStreamSubscription!.cancel();
           tripStreamSubscription!=null;
           resetAppNow();
           Restart.restartApp();
         }
        }
      }
    });
  }

  displayTripRequestContainer() {
    requestContainerHeight = 0;
    tripContainerHeight = 291;
    bottomMapPadding = 281;
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;
    }
    var userPickUpLocationLatLng = LatLng(
        currentPositionOfUser1!.latitude, currentPositionOfUser1!.longitude);

    var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(
        driverCurrentLocationLatLng, userPickUpLocationLatLng);

    if (directionDetailsPickup == null) {
      return;
    }

    setState(() {
      tripStatusDisplay =
          "Driver is Coming - ${directionDetailsPickup.durationTextString}";
    });

    requestingDirectionDetailsInfo = false;
  }

  updateFromDriverCurrentLocationToDropOffDestination(
      driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).dropOffLocation;
      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePosition!,
          dropOffLocation.longitudePosition!);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng,
              userDropOffLocationLatLng);

      if (directionDetailsPickup == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
      });
      requestingDirectionDetailsInfo = false;
    }
  }

  /*updateAvailableNearbyOnlineDriversOnMap() async {
    List<GeoPoint> removedMarkers=ManageDriverMethods.nearbyOnlineDriversList.map((removedGeo)
    =>  GeoPoint(latitude: removedGeo.latDriver!, longitude: removedGeo.lngDriver!)).toList();
    mapController.removeMarkers(removedMarkers);
    ManageDriverMethods.nearbyOnlineDriversList.forEach((element) async{
       await mapController.addMarker(
                      GeoPoint(
                          latitude: element.latDriver!,
                          longitude: element!.lngDriver!),
                      markerIcon: const MarkerIcon(
                        icon: Icon(
                          CupertinoIcons.car,
                          size: 16,
                          color: Colors.pink,
                        ),
                      ),
                      angle: pi / 3,
                      iconAnchor: IconAnchor(
                        anchor: Anchor.center,
                      ));
    });

  }*/

  initializeGeoFireListener() async {
    await Geofire.initialize('onlineDrivers');
    Geofire.queryAtLocation(currentPositionOfUser1!.latitude,
        currentPositionOfUser1!.longitude, 22)!
      ..listen((driverEvent) async {
        print('aaa');
        if (driverEvent != null) {
          var onlineDriverChild = driverEvent['callBack'];
          switch (onlineDriverChild) {
            case Geofire.onKeyEntered:
              print('//////////////onKeyEntered');
              OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
              onlineNearbyDrivers.uidDriver = driverEvent['key'];
              onlineNearbyDrivers.latDriver = driverEvent['latitude'];
              onlineNearbyDrivers.lngDriver = driverEvent['longitude'];

              await mapController
                  .addMarker(
                      GeoPoint(
                          latitude: onlineNearbyDrivers.latDriver!,
                          longitude: onlineNearbyDrivers!.lngDriver!),
                      markerIcon: MarkerIcon(
                        assetMarker: AssetMarker(
                            image: AssetImage('assets/images/tracking1.png')),
                      ),
                      /*const MarkerIcon(
                        icon: Icon(
                          CupertinoIcons.car,
                          size: 16,
                          color: Colors.pink,
                        ),
                      ),*/
                      angle: pi / 3,
                      iconAnchor: IconAnchor(
                        anchor: Anchor.center,
                      ))
                  .then((value) {
                ManageDriverMethods.nearbyOnlineDriversList
                    .add(onlineNearbyDrivers);
              });

              break;
            case Geofire.onKeyExited:
              print(
                  '//////////////onKeyExited ${driverEvent['latitude']}:${driverEvent['longitude']}');
              var oldDriver = ManageDriverMethods.getDriver(driverEvent["key"]);
              await mapController
                  .removeMarker(GeoPoint(
                      latitude: oldDriver.latDriver!,
                      longitude: oldDriver.lngDriver!))
                  .then((value) {
                ManageDriverMethods.removeDriverFromList(driverEvent["key"]);
              });

              break;
            case Geofire.onKeyMoved:
              print(
                  '//////////////onKeyMoved ${driverEvent['latitude']}:${driverEvent['longitude']}');
              OnlineNearbyDrivers oldDriver =
                  ManageDriverMethods.getDriver(driverEvent["key"]);
              OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
              onlineNearbyDrivers.uidDriver = driverEvent["key"];
              onlineNearbyDrivers.latDriver = driverEvent["latitude"];
              onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
              await mapController
                  .changeLocationMarker(
                      oldLocation: GeoPoint(
                          latitude: oldDriver.latDriver!,
                          longitude: oldDriver.lngDriver!),
                      newLocation: GeoPoint(
                          latitude: onlineNearbyDrivers.latDriver!,
                          longitude: onlineNearbyDrivers.lngDriver!))
                  .then((value) {
                ManageDriverMethods.updateOnlineNearbyDriversLocation(
                    onlineNearbyDrivers);
              });

              break;
            case Geofire.onGeoQueryReady:
              print('//////////////onKeyGeoQueryReady');
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('драйверы загружены')));
              nearbyOnlineDriversKeysLoaded = true;
              break;
          }
          ManageDriverMethods.nearbyOnlineDriversList.forEach((element) {
            print(
                '////${element.uidDriver}: ${element.latDriver}-${element.lngDriver}');
          });
        }
      });
  }

  noDriverAvailable() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InfoDialog(
              title: 'No Driver Available',
              description:
                  'No driver found in the nearby location. Please try again shortly.',
            ));
  }

  searchDriver() async {
    if (availableNearbyOnlineDriversList!.length == 0) {

      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }


    var currentDriver = availableNearbyOnlineDriversList![0];
    //возможно здесь удалить маркер
    //send notification to this currentDriver
    await sendNotificationToDriver(currentDriver);
    availableNearbyOnlineDriversList!.removeAt(0);


    print('колво ${ManageDriverMethods.nearbyOnlineDriversList.length}');

  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    //update driver's newTripStatus-assign tripID to current driver
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentDriver.uidDriver.toString())
        .child('newTripStatus');
    currentDriverRef.set(tripRequestRef!.key);
    //get current driver device recognition token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentDriver.uidDriver.toString())
        .child('deviceToken');
    tokenOfCurrentDriverRef.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        String deviceToken = dataSnapshot.snapshot.value.toString();
        //send notification
        PushNotificationService.sendNotificationToSelectedDriver(
            deviceToken, context, tripRequestRef!.key.toString());
      } else {
        return;
      }
      const oneTickPerSec = Duration(seconds: 1);
      var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
        requestTimeoutDriver = requestTimeoutDriver - 1;
        //when trip request is not requesting means trip request cancelled-stop timer
        if (stateOfApp != 'requesting') {
          timer.cancel();
          currentDriverRef.set('canceled');
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
        }
        //when trip request is accepted by online nearest available driver
        currentDriverRef.onValue.listen((dataSnapshot) {
          if (dataSnapshot.snapshot.value.toString() == 'accepted') {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });

        //if 20 sec passed-send notification to next nearest driver
        if (requestTimeoutDriver == 0) {
          currentDriverRef.set('timeout');
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
          //send notidication next driver
          searchDriver();
        }
      });
    });
  }

  @override
  void dispose() {
    Geofire.stopListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyIcon();
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
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>TripsHistoryPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      Icons.history,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  title: Text(
                    'History',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AboutPage()));
                },
                child: ListTile(
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
          OSMFlutter(
            controller: mapController,
            osmOption: OSMOption(
              enableRotationByGesture: false,
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
                roadColor: Colors.deepOrange,
                roadBorderWidth: 10,
              ),
            ),
            onLocationChanged: (GeoPoint geo) async {
              //currentPositionOfUser1 = geo;
              //await mapController.currentLocation();
              print('ИЗменить${geo.toString()}');
            },
            onMapIsReady: (isReady) async {
              if (isReady) {
                await Future.delayed(Duration(seconds: 1), () async {
                  await mapController.currentLocation();
                  await mapController.enableTracking(
                    enableStopFollow: false,
                    disableUserMarkerRotation: true,
                    // anchor: Anchor.left,  here anchor is testing you can put anchor that match with your need
                  );
                  Position p=await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.bestForNavigation);
                  currentPositionOfUser1=GeoPoint(latitude: p.latitude, longitude: p.longitude);
                  //currentPositionOfUser1 = await mapController.myLocation();
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
                    isDrawerOpened ? Icons.menu : Icons.close,
                    color: Colors.black87,
                  ),
                ),
              ),
              onTap: () {
                if (isDrawerOpened) {
                  sKey.currentState!.openDrawer();
                } else {
                  resetAppNow();
                }
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
                                    .dropOffLocation!
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                    onTap: () {
                                      setState(() {
                                        stateOfApp = 'requesting';
                                      });
                                      displayRequestContainer();
                                      //get nearest available online drivers
                                      availableNearbyOnlineDriversList =List.from(ManageDriverMethods
                                          .nearbyOnlineDriversList);
                                          ;

                                      //search driver
                                      searchDriver();
                                    },
                                  ),
                                  Text(
                                    (tripDirectionDetailsInfo != null)
                                        ? '\$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!)).toString()}'
                                        : '',
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
            ),
          ),
          //request container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              //color: Colors.black54,
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ]),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 200,
                      child: LoadingAnimationWidget.flickr(
                        leftDotColor: Colors.greenAccent,
                        rightDotColor: Colors.pinkAccent,
                        size: 50,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1.5, color: Colors.grey)),
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                      onTap: () {
                        resetAppNow();
                        cancelRideRequest();
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
          //trip details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white24,
                      blurRadius: 15,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ]),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    //trip status display text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tripStatusDisplay,
                          style: TextStyle(fontSize: 19, color: Colors.grey),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 19,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),
                    SizedBox(
                      height: 19,
                    ),
                    //image - driver name and car details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            photoDriver == ''
                                ? 'https://firebasestorage.googleapis.com/v0/b/flutter-uber-clone-with-ef45b.appspot.com/o/avatarman.png?alt=media&token=b33fd3a4-f6dd-43a2-b0a7-1201b3bd50af'
                                : photoDriver,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameDriver,
                              style:
                                  TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                            Text(
                              carDetailsDriver,
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(
                      height: 19,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),
                    SizedBox(
                      height: 19,
                    ),
                    //call driver btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(25)),
                                    border: Border.all(
                                      width: 1,
                                      color: Colors.white,
                                    )),
                                child: Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: 11,
                              ),
                              Text(
                                'Call',
                                style: TextStyle(color: Colors.grey),
                              )
                            ],
                          ),
                          onTap: () {
                            launchUrl(Uri.parse('tel://$phoneNumberDriver'));
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
