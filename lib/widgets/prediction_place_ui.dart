import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/appinfo/app_info.dart';
import 'package:uber_clone_user_app/models/address_model.dart';
import 'package:uber_clone_user_app/models/prediction_model.dart';
import 'package:uber_clone_user_app/widgets/loading_dialog.dart';
import 'package:yandex_geocoder/yandex_geocoder.dart';

class PredictionPlaceUI extends StatefulWidget {
  PredictionModel? predictionPlaceData;

  PredictionPlaceUI({Key? key, this.predictionPlaceData}) : super(key: key);

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {

  fetchClickedPlaceDetails(String ws)async {
    showDialog(
      barrierDismissible: false,
        context: context,
        builder: (context)=>LoadingDialog(messageText: 'Getting details...'));
    
    AddressModel dropOffLocation=AddressModel();
    dropOffLocation.placeName=widget.predictionPlaceData!.main_text;
    dropOffLocation.latitudePosition=widget.predictionPlaceData!.latitude;
    dropOffLocation.longitudePosition=widget.predictionPlaceData!.longitude;
    dropOffLocation.placeID='1';
    Provider.of<AppInfo>(context,listen: false)
    .updateDropOffLocation(dropOffLocation);
    Navigator.pop(context);
    Navigator.pop(context,'placeSelected');


  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: SizedBox(
        child: Column(
          children: [
            SizedBox(height: 10,),
            Row(
              children: [
                Icon(
                  Icons.share_location,
                  color: Colors.grey,
                ),
                SizedBox(
                  width: 13,
                ),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictionPlaceData!.main_text.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 3,),
                    Text(
                      widget.predictionPlaceData!.secondary_text.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ))
              ],
            ),
            SizedBox(height: 10,),
          ],
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
      ),
      onPressed: () {
        fetchClickedPlaceDetails(widget.predictionPlaceData!.place_id.toString());
      },
    );
  }
}
