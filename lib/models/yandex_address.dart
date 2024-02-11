class YandexAddress {
  String type;
  YandexAddressProperties properties;
  List<Feature> features;

  YandexAddress({
    required this.type,
    required this.properties,
    required this.features,
  });

}

class Feature {
  FeatureType type;
  Geometry geometry;
  FeatureProperties properties;

  Feature({
    required this.type,
    required this.geometry,
    required this.properties,
  });

}

class Geometry {
  GeometryType type;
  List<double> coordinates;

  Geometry({
    required this.type,
    required this.coordinates,
  });

}

enum GeometryType {
  POINT
}

class FeatureProperties {
  String name;
  String description;
  List<List<double>> boundedBy;
  String uri;
  GeocoderMetaData geocoderMetaData;

  FeatureProperties({
    required this.name,
    required this.description,
    required this.boundedBy,
    required this.uri,
    required this.geocoderMetaData,
  });

}

class GeocoderMetaData {
  Precision precision;
  String text;
  String kind;

  GeocoderMetaData({
    required this.precision,
    required this.text,
    required this.kind,
  });

}

enum Precision {
  OTHER,
  STREET
}

enum FeatureType {
  FEATURE
}

class YandexAddressProperties {
  ResponseMetaData responseMetaData;

  YandexAddressProperties({
    required this.responseMetaData,
  });

}

class ResponseMetaData {
  SearchResponse searchResponse;
  SearchRequest searchRequest;

  ResponseMetaData({
    required this.searchResponse,
    required this.searchRequest,
  });

}

class SearchRequest {
  String request;
  int skip;
  int results;
  List<List<double>> boundedBy;

  SearchRequest({
    required this.request,
    required this.skip,
    required this.results,
    required this.boundedBy,
  });

}

class SearchResponse {
  int found;
  String display;
  List<List<double>> boundedBy;

  SearchResponse({
    required this.found,
    required this.display,
    required this.boundedBy,
  });

}
