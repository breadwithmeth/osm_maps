import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

var URL_NOSM = 'nominatim.openstreetmap.org';
// var URL_OSRM = 'router.project-osrm.org';
var URL_OSRM = '217.78.239.201:5000';
// var URL_OSRM = 'osm.naliv.kz:5000';

var URL_YANDEX = 'geocode-maps.yandex.ru';
Future<Map?> getCoordinatesFromText(String address) async {
  var url = Uri.https(URL_NOSM, 'search', {
    "q": address,
    "format": "geojson",
    "polygon_kml": "1",
    "addressdetails": "1",
    "accept-language": "ru"
  });
  var response = await http.get(url);

  // List<dynamic> list = json.decode(response.body);
  Map? data = json.decode(utf8.decode(response.bodyBytes));
  return data;
}

Future<Map?> getRoute(LatLng store, LatLng client) async {
  String store1 = store.latitude.toString();
  String store2 = store.longitude.toString();
  String client1 = client.latitude.toString();
  String client2 = client.longitude.toString();
  var url = Uri.http(
      URL_OSRM,
      "/route/v1/driving/$store2,$store1;$client2,$client1",
      {"overview": "simplified", "steps": "true", "alternatives": "1"});
  var response = await http.get(url);

  // List<dynamic> list = json.decode(response.body);
  Map? data = json.decode(utf8.decode(response.bodyBytes));
  print(data);
  return data;
}

Future<Map?> getCoordinatesFromTextYandex(String address) async {
  var url = Uri.https(URL_YANDEX, '/1.x/', {
    "apikey": 'c70d31a7-51af-40fd-858e-129c9b4d603f',
    "geocode": address,
    "format": "json",
  });
  var response = await http.get(url);

  // List<dynamic> list = json.decode(response.body);
  Map? data = json.decode(utf8.decode(response.bodyBytes));
  return data;
}
