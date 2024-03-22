

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/appinfo/app_info.dart';
import '../global/global_var.dart';
import 'package:http/http.dart' as http;

class PushNotificationService{

  static sendNotificationToSelectedDriver(String deviceToken,BuildContext context,String tripID)async {
    String dropOffDestinationAddress=Provider.of<AppInfo>(context,listen: false).dropOffLocation!.placeName.toString();
    String pickUpAddress=Provider.of<AppInfo>(context,listen: false).pickUpLocation!.placeName.toString();

    Map<String, String> headerNotificationMap = {
      'Content-Type': 'application/json',
      'Authorization': serverKeyFCM,
    };
    Map titleBodyNotificationMap = {
      'title': 'Net TRIP REQUEST from $userName',
      'body':'PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress'
    };
    Map dataMapNotification={
      'click_action':'FLUTTER_NOTIFICATION_CLICK',
      'id':'1',
      'status':'done',
      'tripID':tripID
     /*'userName':userName,
      'dropOffDestinationAddress':dropOffDestinationAddress*/
    };
    Map bodyNotificationMap={
      'notification':titleBodyNotificationMap,
      'data':dataMapNotification,
      'priority':'high',
      'to':deviceToken,
    };
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headerNotificationMap,
      body: jsonEncode(bodyNotificationMap),
    );
  }
}