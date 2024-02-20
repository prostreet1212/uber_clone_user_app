import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/appinfo/app_info.dart';
import 'package:uber_clone_user_app/models/address_model.dart';
import 'package:yandex_geocoder/yandex_geocoder.dart';
import '../pages/home_page.dart';
import '../global/global_var.dart';
import 'package:http/http.dart' as http;

import '../models/direction_details.dart';

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

  static sendRequestToAPI(String apiUrl)async{
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
  }

  //reverse geocoding
  static Future<String> convertGeoGraphicCoordinatesIntoHumanReadableAddress(
      GeoPoint position, BuildContext context) async {
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
    
    /*final YandexGeocoder geocoder =
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
    return humanReadableAddress;*/

  }

  //directions API
static Future<DirectionDetails> getDirectionDetailsFromAPI(LatLng source,LatLng destination,MapController controller)async{

    RoadInfo roadInfo = await controller.drawRoad(
    GeoPoint(latitude: source.latitude, longitude: source.longitude),
    GeoPoint(latitude: destination.latitude, longitude: destination.longitude),
    roadType: RoadType.car,
  );
    print('Расстояние: ${roadInfo.distance}, длительность ${roadInfo.duration}');
    

    return DirectionDetails(distanceTextString: '${roadInfo.distance!.toStringAsFixed(2)} км.',durationTextString: '${(roadInfo.duration!/60).toStringAsFixed(2)} мин.',distanceValueDigits: 15,durationValueDigits: 5,encodedPoints: 'points');
}

}
