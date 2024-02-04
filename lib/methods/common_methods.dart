import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/appinfo/app_info.dart';
import 'package:uber_clone_user_app/models/address_model.dart';
import 'package:yandex_geocoder/yandex_geocoder.dart';

import '../global/global_var.dart';
import 'package:http/http.dart' as http;

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();
    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackBar(
          'your Internet is not available. Check your connection. Try Again',
          context);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /*static sendRequestToAPI(String apiUrl)async{
    http.Response responseFromAPI=await http.get(Uri.parse(apiUrl));
    try{
      if(responseFromAPI.statusCode==200){
        String dataFromApi=responseFromAPI.body;
        var dataDecoded=jsonDecode(dataFromApi);
        return dataDecoded;
      }else{
        return 'error';
      }
    }catch(errorMsg){
return 'error';
    }
  }*/

  //reverse geocoding
  static Future<String> convertGeoGraphicCoordinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    /*String  humanReadableAddress='';
    String apiGeoCodingUrl='https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey';
    var responseFromAPI=await sendRequestToAPI(apiGeoCodingUrl);
    if(responseFromAPI!='error'){
      humanReadableAddress=responseFromAPI['results'][0]['formatted_address'];
      print('humanReadableAddress=${humanReadableAddress}');
    }
    return humanReadableAddress;*/
    final YandexGeocoder geocoder =
        YandexGeocoder(apiKey: 'd9b87948-441f-4d14-997c-0480020df2bc');
    final GeocodeResponse geocodeFromPoint =
        await geocoder.getGeocode(GeocodeRequest(
      geocode: PointGeocode(
          latitude: position.latitude, longitude: position.longitude),
      lang: Lang.enEn,
    ));
    String humanReadableAddress = geocodeFromPoint.firstAddress!.formatted!;
    AddressModel model = AddressModel();
    model.humanReadableAddress = humanReadableAddress;
    model.latitudePosition = position.latitude;
    model.longitudePosition = position.longitude;

    Provider.of<AppInfo>(context,listen: false).updatePickUpLocation(model);

    return humanReadableAddress;
  }

}
