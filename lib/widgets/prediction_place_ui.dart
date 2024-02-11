import 'package:flutter/material.dart';
import 'package:uber_clone_user_app/models/prediction_model.dart';

class PredictionPlaceUI extends StatefulWidget {
  PredictionModel? predictionPlaceData;

  PredictionPlaceUI({Key? key, this.predictionPlaceData}) : super(key: key);

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
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
      onPressed: () {},
    );
  }
}
