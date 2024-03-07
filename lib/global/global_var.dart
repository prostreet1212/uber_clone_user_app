

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName='';
String userPhone='';
String userID=FirebaseAuth.instance.currentUser!.uid;
String googleMapKey='AIzaSyBPq2bCfprMYNLBgL_1u4cLmJIZitUrMPw';
String serverKeyFCM='key=AAAAG7j5Gms:APA91bEVAwnz7BNu5p3v8-8k1wrGOWfoblgNtgCkujccrIVh_MuP4l0HksX3mxQDtFzPZvXiQOfVpQ8QRFRWMfqvIgXmCHy693wGkBg9NFnVbbvE-YoeT61zOazs0u25U8CgeqOeNJEg';
 const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);