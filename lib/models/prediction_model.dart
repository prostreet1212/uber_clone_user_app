
class PredictionModel{
  String? place_id;
  String? main_text;
  String? secondary_text;
  double? latitude;
  double? longitude;

  PredictionModel({this.place_id, this.main_text, this.secondary_text,this.latitude,this.longitude});

  PredictionModel.fromJson(Map<String,dynamic> json){
    place_id=json['place_id'];
    main_text=json['structured_formatting']['main_text'];
    secondary_text=json['structured_formatting']['secondary_text'];
  }
}