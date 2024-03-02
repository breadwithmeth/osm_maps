import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:osm_maps/api.dart';
import 'package:latlong2/latlong.dart';
import 'unpack_polyline.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: Main(),
  ));
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final mapController = MapController();
  List<Polyline> _polylines = [];
  int currentEngine = 1;
  late Store currentStore;
  TextEditingController _street = TextEditingController();
  TextEditingController _house = TextEditingController();
  TextEditingController _corp = TextEditingController();
  int _dist = 0;
  List<Widget> _objects = [];

  List<Marker> _markers = [];

  List<Widget> _dists = [];

  late Marker _store;
  late Marker _client;

  List<Store> _stores = [
    Store(1, "Горького 66/1", "Павлодар", LatLng(52.271643, 76.950011)),
    Store(2, "Бекхожина 3/2", "Павлодар", LatLng(52.249676, 76.954269)),
    Store(3, "Академика Сатпаева 21", "Павлодар", LatLng(52.293063, 76.942267)),
    Store(4, "Толстого 90", "Павлодар", LatLng(52.276497, 76.975226)),
  ];
  Future<void> _getCoordinatesFromText() async {
    String query = currentStore.city;

    if (_street.text.isNotEmpty) {
      query += ", " + _street.text;
    }
    if (_house.text.isNotEmpty) {
      query += " " + _house.text;
    }
    if (_corp.text.isNotEmpty) {
      query += "/" + _corp.text;
    }

    if (currentEngine == 2) {
      Map? data = await getCoordinatesFromText(query);

      List objects = [];
      List<Widget> objectsAddr = [];
      if (data?["features"] != null && data?["features"] != []) {
        objects = data?["features"];
        objects.forEach((element) {
          print(element);
          objectsAddr.add(GestureDetector(
            onTap: () async {
              Map? route = await getRoute(
                currentStore.coordinates,
                LatLng(
                  element["geometry"]["coordinates"][1],
                  element["geometry"]["coordinates"][0],
                ),
              );
              List<Polyline> polylines = [];
              List g_routes = route!["routes"];
              int i = 0;
              List<Color> clrs = [Colors.blue, Colors.pink, Colors.purple];
              for (var element in g_routes) {
                num dist = 0;

                ++i;
                dist = dist + element["distance"];
                polylines.add(Polyline(
                    points:
                        decodePolyline(element["geometry"]).unpackPolyline(),
                    color: clrs[i],
                    strokeWidth: 15));
              }
              // setState(() {
              //   _dist = dist.toInt();
              //   _polylines = polylines;
              //   print(dist);
              // });
              mapController.move(
                  LatLng(
                    element["geometry"]["coordinates"][1],
                    element["geometry"]["coordinates"][0],
                  ),
                  15);
              mapController.fitCamera(CameraFit.coordinates(coordinates: [
                currentStore.coordinates,
                LatLng(
                  element["geometry"]["coordinates"][1],
                  element["geometry"]["coordinates"][0],
                ),
              ], padding: EdgeInsets.all(90)));
              setState(() {
                _client = Marker(
                    point: LatLng(
                      element["geometry"]["coordinates"][1],
                      element["geometry"]["coordinates"][0],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.purple,
                      size: 32,
                    ));
              });
            },
            child: AddressObject(
                coordinates: LatLng(
                  element["geometry"]["coordinates"][1],
                  element["geometry"]["coordinates"][0],
                ),
                display_name: element["properties"]["display_name"]),
          ));
        });
      }

      setState(() {
        _objects = [];
        _objects = objectsAddr;
      });
      mapController.move(LatLng(66, 72), 14);
    }

    if (currentEngine == 1) {
      Map? data = await getCoordinatesFromTextYandex(query);
      List objects = [];
      List<Widget> objectsAddr = [];
      if (data?["response"]["GeoObjectCollection"]["featureMember"] != null &&
          data?["response"]["GeoObjectCollection"]["featureMember"] != []) {
        objects = data?["response"]["GeoObjectCollection"]["featureMember"];

        objects.forEach((element) {
          double lat = double.parse(
              element["GeoObject"]["Point"]["pos"].toString().split(' ')[1]);
          double lon = double.parse(
              element["GeoObject"]["Point"]["pos"].toString().split(' ')[0]);
          print(lat);
          objectsAddr.add(GestureDetector(
            onTap: () async {
              Map? route = await getRoute(
                currentStore.coordinates,
                LatLng(lat, lon),
              );
              List<Polyline> polylines = [];
              List g_routes = route!["routes"];
              num dist = 0;
              int i = 0;
              List<Color> clrs = [
                Colors.blue,
                Colors.pink,
                Colors.purple,
                Colors.orange
              ];
              List<Widget> dists = [];
              g_routes.forEach((element) {
                dists.add(Text(
                  element["distance"].toString() + "м",
                  style: TextStyle(color: clrs[i]),
                ));
                dist = dist + element["distance"];
                polylines.add(Polyline(
                    points:
                        decodePolyline(element["geometry"]).unpackPolyline(),
                    color: clrs[i],
                    strokeWidth: 15));
                i++;
              });
              setState(() {
                _dist = dist.toInt();
                _polylines = polylines;
                print(dist);
                _dists = dists;
              });
              mapController.move(LatLng(lat, lon), 15);
              mapController.fitCamera(CameraFit.coordinates(coordinates: [
                currentStore.coordinates,
                LatLng(lat, lon),
              ], padding: EdgeInsets.all(90)));
              setState(() {
                _client = Marker(
                    point: LatLng(lat, lon),
                    child: Icon(
                      Icons.person,
                      color: Colors.purple,
                      size: 32,
                    ));
              });
            },
            child: AddressObject(
                coordinates: LatLng(lat, lon),
                display_name: element["GeoObject"]["name"]),
          ));
        });
        setState(() {
          _objects = [];
          _objects = objectsAddr;
        });
        mapController.move(LatLng(66, 72), 14);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _client = Marker(point: LatLng(0, 0), child: Icon(Icons.abc));
      _store = Marker(point: LatLng(0, 0), child: Icon(Icons.abc));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "OSM КАРТЫ",
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("OpenStreetMap® "),
                Text("OpenStreetMap Foundation(OSMF) "),
                Text("OSRM "),
                Text("YANDEX GEOCODER ")
              ],
            )
          ],
        ),
        body: Container(
          padding: EdgeInsets.only(left: 50, top: 0),
          child: Row(
            children: [
              Flexible(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          DropdownMenu(
                              hintText: "Поисковый движок",
                              inputDecorationTheme: InputDecorationTheme(
                                  border: UnderlineInputBorder()),
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                    value: 1, label: "geocode-maps.yandex.ru"),
                                DropdownMenuEntry(
                                    value: 2,
                                    label: "nominatim.openstreetmap.org"),
                              ],
                              onSelected: (value) {
                                setState(() {
                                  if (value != null) {
                                    currentEngine = value;
                                  }
                                });
                              }),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            flex: 1,
                            child: DropdownMenu(
                                hintText: "Город",
                                inputDecorationTheme: InputDecorationTheme(
                                    border: UnderlineInputBorder()),
                                dropdownMenuEntries:
                                    _stores.map<DropdownMenuEntry>((e) {
                                  return DropdownMenuEntry(
                                      value: e.id, label: e.name);
                                }).toList(),
                                //  [
                                //   DropdownMenuEntry(
                                //       value: 1, label: "Павлодар, Горького 66/1"),
                                //   DropdownMenuEntry(
                                //       value: 2, label: "Павлодар, Академика Сатпаева 21"),
                                //   DropdownMenuEntry(
                                //       value: 3, label: "Павлодар, Бекхожина 3/2"),
                                //   DropdownMenuEntry(
                                //       value: 4, label: "Павлодар, Толстого 90"),
                                // ],
                                onSelected: (value) {
                                  setState(() {
                                    currentStore =
                                        _stores.firstWhere((element) {
                                      mapController.move(
                                          element.coordinates, 16);
                                      _store = Marker(
                                          point: element.coordinates,
                                          child: Icon(
                                            Icons.stop_circle,
                                            color: Colors.purple,
                                            size: 32,
                                          ));
                                      if (element.id == value) {
                                        return true;
                                      } else {
                                        return false;
                                      }
                                    });
                                  });
                                }),
                          ),
                          Flexible(child: Text(_dist.toString() + "м")),
                          Flexible(
                              child: Row(
                            children: _dists,
                          ))
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: TextField(
                              controller: _street,
                              decoration: InputDecoration(
                                  label: Text("Улица"),
                                  border: OutlineInputBorder()),
                            ),
                            flex: 30,
                          ),
                          Spacer(),
                          Flexible(
                            child: TextField(
                              controller: _house,
                              decoration: InputDecoration(
                                  label: Text("Дом"),
                                  border: OutlineInputBorder()),
                            ),
                            flex: 10,
                          ),
                          Text(
                            " / ",
                            style: TextStyle(fontSize: 32),
                          ),
                          Flexible(
                            child: TextField(
                              controller: _corp,
                              decoration: InputDecoration(
                                  label: Text("Корпус"),
                                  border: OutlineInputBorder()),
                            ),
                            flex: 10,
                          ),
                          Spacer(),
                          Flexible(
                              flex: 10,
                              child: IconButton(
                                  onPressed: _getCoordinatesFromText,
                                  icon: Icon(Icons.search)))
                        ],
                      ),
                    ],
                  )),
                  Flexible(
                      child: ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          padding: const EdgeInsets.all(8),
                          itemCount: _objects.length,
                          itemBuilder: (BuildContext context, int index) {
                            return _objects[index];
                          })),
                ],
              )),
              Flexible(
                  child: Column(
                children: [
                  Flexible(
                      child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.2),
                              offset: Offset(-10, -10),
                              blurRadius: 30,
                              spreadRadius: 5),
                          BoxShadow(
                              color: Colors.black54,
                              offset: Offset(-5, -5),
                              blurRadius: 10,
                              spreadRadius: 10),
                        ],
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(30))),
                    // width: MediaQuery.of(context).size.width * 0.4,
                    // height: MediaQuery.of(context).size.height * 0.9,
                    width: double.maxFinite,
                    height: double.maxFinite,
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: LatLng(52.265531, 76.966899),
                        initialZoom: 15,
                        onMapReady: () {
                          mapController.mapEventStream.listen((evt) {});
                          // And any other `MapController` dependent non-movement methods
                        },
                      ),
                      children: [
                        TileLayer(
                          // retinaMode: true,
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'dev.fleaflet.flutter_map.example',
                          // Plenty of other options available!
                        ),
                        PolylineLayer(polylines: _polylines),
                        MarkerLayer(
                          markers: [_client, _store],
                        ),
                      ],
                    ),
                  ))
                ],
              )),
            ],
          ),
        ));
  }
}

class Store {
  final int id;
  final String name;
  final String city;
  final LatLng coordinates;

  Store(this.id, this.name, this.city, this.coordinates);
}

class AddressObject extends StatefulWidget {
  const AddressObject(
      {super.key, required this.coordinates, required this.display_name});
  final LatLng coordinates;
  final String display_name;
  @override
  State<AddressObject> createState() => _AddressObjectState();
}

class _AddressObjectState extends State<AddressObject> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.display_name);
  }
}
