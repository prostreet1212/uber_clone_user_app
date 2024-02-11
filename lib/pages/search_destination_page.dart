import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone_user_app/global/global_var.dart';
import 'package:uber_clone_user_app/methods/common_methods.dart';
import 'package:uber_clone_user_app/models/prediction_model.dart';
import 'package:uber_clone_user_app/models/yandex_address.dart';
import 'package:uber_clone_user_app/widgets/prediction_place_ui.dart';

import '../appinfo/app_info.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({Key? key}) : super(key: key);

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();
  List<PredictionModel> dropOffPredicationsPlacesList = [];

  //test
  searchLocation(String locationName) async {
    if (locationName.length > 1) {
     /* List<PredictionModel> predictionsList = [
        PredictionModel(
            place_id: '1', main_text: 'kotlas', secondary_text: 'russia'),
        PredictionModel(
            place_id: '2', main_text: 'krasnoborsk', secondary_text: 'russia'),
        PredictionModel(
            place_id: '3', main_text: 'koryazhma', secondary_text: 'russia'),
      ];
      setState(() {
        dropOffPredicationsPlacesList = predictionsList;
      });*/
      //yandex
      String apiPlaceUrl='https://search-maps.yandex.ru/v1/?text=$locationName&type=geo&lang=en_US&apikey=857ba51b-df09-45eb-b94d-2b3be63a58bf';
      var responseFromPlacesAPI=await CommonMethods.sendRequestToAPI(apiPlaceUrl);
      var predictionResultInJson=responseFromPlacesAPI['features'];
      var predictionsList=(predictionResultInJson as List).map((e) {
        return PredictionModel(place_id: '1',main_text: e['properties']['name'],secondary_text: e['properties']['description']);
        //e['properties'];
        print(e['properties']['name']);
      }).toList();
      setState(() {
        dropOffPredicationsPlacesList=predictionsList;
      });

      //google
      /*String apiPlaceUrl='https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:ae';
      var responseFromPlacesAPI=await CommonMethods.sendRequestToAPI(apiPlaceUrl);
      if(responseFromPlacesAPI=='error'){
        return;
      }
      if(responseFromPlacesAPI['status']=='OK'){
        var predictionResultInJson=responseFromPlacesAPI['predictions'];
        var predictionsList=(predictionResultInJson as List).map((eachPlacePrediction) => PredictionModel
            .fromJson(eachPlacePrediction)).toList();
        setState(() {
          dropOffPredicationsPlacesList=predictionsList;
        });
      }*/
    }
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfo>(context, listen: false)
            .pickUpLocation!
            .humanReadableAddress ??
        '';
    pickUpTextEditingController.text = userAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                height: 230,
                decoration: BoxDecoration(color: Colors.black12, boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7))
                ]),
                child: Padding(
                  padding:
                      EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 6,
                      ),
                      //icon button-title
                      Stack(
                        children: [
                          GestureDetector(
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          Center(
                            child: Text(
                              'Set Dropoff Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 18,
                      ),
                      //pickup text field
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/initial.png',
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(
                            width: 18,
                          ),
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: TextField(
                                controller: pickUpTextEditingController,
                                decoration: InputDecoration(
                                    hintText: 'Pickup Address',
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        left: 11, top: 9, bottom: 9)),
                              ),
                            ),
                          ))
                        ],
                      ),
                      SizedBox(
                        height: 11,
                      ),
                      //destination text field
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/final.png',
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(
                            width: 18,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: TextField(
                                  controller: destinationTextEditingController,
                                  onChanged: (inputText) {
                                    searchLocation(inputText);
                                  },
                                  decoration: InputDecoration(
                                      hintText: 'Destination Address',
                                      fillColor: Colors.white12,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //display prediction results
            (dropOffPredicationsPlacesList.length > 0)
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListView.separated(
                      padding: EdgeInsets.all(0),
                      itemCount: dropOffPredicationsPlacesList.length,
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                        return Card(
                          elevation: 3,
                          child: PredictionPlaceUI(
                            predictionPlaceData: dropOffPredicationsPlacesList[index],
                          ),
                        );
                        },
                      separatorBuilder: (context,  index) {
                        return SizedBox(height: 2,);
                      },),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
