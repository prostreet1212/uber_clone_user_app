

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName='';
String userPhone='';
String userID=FirebaseAuth.instance.currentUser!.uid;
String googleMapKey='AIzaSyBPq2bCfprMYNLBgL_1u4cLmJIZitUrMPw';
 const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);