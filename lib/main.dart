import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:osm_maps/api.dart';
import 'package:latlong2/latlong.dart';
import 'unpack_polyline.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

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
  List<Widget> _routeWidgets = [];
  List<Marker> _markers = [];

  List<Map> _dists = [];
  List<Map> _routes = [];
  late Marker _store;
  late Marker _client;

  List<Store> _stores = [
    Store(1, "Горького 66/1", "Павлодар", LatLng(52.271643, 76.950011),
        Colors.amber),
    Store(2, "Бекхожина 3/2", "Павлодар", LatLng(52.249676, 76.954269),
        Colors.teal),
    Store(3, "Академика Сатпаева 21", "Павлодар", LatLng(52.293063, 76.942267),
        Colors.deepPurple),
    Store(4, "Толстого 90", "Павлодар", LatLng(52.276497, 76.975226),
        Colors.blueGrey),
  ];
  Future<void> _getCoordinatesFromText() async {
    String query = "Павлодар ";

    if (_street.text.isNotEmpty) {
      query += ", " + _street.text;
    }
    if (_house.text.isNotEmpty) {
      query += " " + _house.text;
    }
    if (_corp.text.isNotEmpty) {
      query += "/" + _corp.text;
    }

    setState(() {
      currentEngine = 1;
    });

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
          objectsAddr.add(TextButton(
            onPressed: () async {
              AddressObject cl_add = AddressObject(
                  coordinates: LatLng(lat, lon),
                  display_name: element["GeoObject"]["name"]);

              // Map? route = await getRoute(
              //   _stores[0].coordinates,
              //   LatLng(lat, lon),
              // );
              // Map? route1 = await getRoute(
              //   _stores[1].coordinates,
              //   LatLng(lat, lon),
              // );
              // Map? route2 = await getRoute(
              //   _stores[2].coordinates,
              //   LatLng(lat, lon),
              // );
              // Map? route3 = await getRoute(
              //   _stores[3].coordinates,
              //   LatLng(lat, lon),
              // );
              // List<Polyline> polylines = [];
              // List g_routes = route!["routes"];
              // num dist = 0;
              // int i = 0;
              // List<Color> clrs = [
              //   Colors.blue,
              //   Colors.pink,
              //   Colors.purple,
              //   Colors.orange
              // ];
              // List<Map> dists = [];
              // g_routes.forEach((element) {
              //   dists.add({"dist": element["distance"], "color": clrs[i]});
              //   // Text(
              //   //   element["distance"].toString() + "м",
              //   //   style: TextStyle(color: clrs[i]),
              //   // )
              //   dist = dist + element["distance"];
              //   polylines.add(Polyline(
              //       points:
              //           decodePolyline(element["geometry"]).unpackPolyline(),
              //       color: clrs[i],
              //       strokeWidth: 15));
              //   i++;
              // });
              List<Polyline> polylines = [];

              List<Map> routes = [];
              List<Widget> routeWidgets = [];
              setState(() {
                _routes = [];
              });
              _stores.forEach((element) async {
                await _getRoute(lat, lon, element).then((value) {
                  Store st = value["store"];
                  double dist = value["dist"];
                  routes.add({"store": st, "dist": dist, "cl_add": cl_add});
                  print(dist);
                  print(st.color.toString());
                  polylines.add(value["pl"]);
                  setState(() {
                    _routes.add({"store": st, "dist": dist});
                  });
                  // Store st = value["store"];
                  // double dist = value["dist"] / 1000;
                  // dist = (dist * 2).round() / 2;
                  // int price = 0;
                  // if (dist <= 1.5) {
                  //   price = 700;
                  // } else {
                  //   if (dist < 5) {
                  //     price = ((dist - 1.5) * 300 + 700).toInt();
                  //   } else {
                  //     price = ((dist - 1.5) * 250 + 700).toInt();
                  //   }
                  // }
                  // routeWidgets.add(ListTile(
                  //   title: Text(st.name + " - " + dist.toString() + "км"),
                  //   subtitle: Text(price.toString()),
                  // ));
                });
              });

              setState(() {
                // _dist = dist.toInt();
                _polylines = polylines;
                // print(dist);
                // _dists = dists;
              });
              print(
                  "==========================================================");
              print(routes);

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

  Future<Map> _getRoute(double lat, double lon, Store store) async {
    Map? route = await getRoute(
      store.coordinates,
      LatLng(lat, lon),
    );
    Polyline polyline = Polyline(points: []);
    List g_routes = route!["routes"];
    num dist = 0;

    g_routes.forEach((element) {
      if (dist == 0) {
        dist = element["distance"];
        polyline = Polyline(
            points: decodePolyline(element["geometry"]).unpackPolyline(),
            color: store.color,
            strokeWidth: 15);
      } else if (dist > element["distance"]) {
        polyline = Polyline(
            points: decodePolyline(element["geometry"]).unpackPolyline(),
            color: store.color,
            strokeWidth: 15);
        dist = element["distance"];
      }
    });
    print({"store": store, "dist": dist, "pl": polyline});
    return {"store": store, "dist": dist, "pl": polyline};
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
                  Flexible(
                      flex: 3,
                      child: ListView.builder(
                        primary: false,
                        shrinkWrap: true,
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          double dist = _routes[index]["dist"] / 1000;
                          dist = (dist * 2).round() / 2;
                          int price = 0;
                          if (dist <= 1.5) {
                            price = 700;
                          } else {
                            if (dist < 5) {
                              price = ((dist - 1.5) * 300 + 700).toInt();
                            } else {
                              price = ((dist - 1.5) * 250 + 700).toInt();
                            }
                          }
                          Store st = _routes[index]["store"];
                          return ListTile(
                            leading: Icon(
                              Icons.pin_drop,
                              color: st.color,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  price.toString() + "тг",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Icon(Icons.route),
                                Text(st.name),
                              ],
                            ),
                            subtitle: Text(dist.toString() + "км"),
                          );
                        },
                      ))
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
                          tileProvider: CancellableNetworkTileProvider(),
                          tileBuilder: _darkModeTileBuilder,

                          // Plenty of other options available!
                        ),
                        PolylineLayer(polylines: _polylines),
                        PolygonLayer(polygons: [
                          Polygon(
                              points: [
                                LatLng(52.275750, 76.962053),
                                LatLng(52.274855, 76.931884),
                                LatLng(52.288173, 76.933815),
                                LatLng(52.328685, 76.883817),
                                LatLng(52.328685, 76.883817),
                                LatLng(52.316904, 77.020287),
                                LatLng(52.306593, 77.022691),
                                LatLng(52.299227, 76.972566),
                                LatLng(52.297333, 76.965013),
                                LatLng(52.284280, 76.966729),
                                LatLng(52.281438, 76.961279)
                              ],
                              color: Colors.pinkAccent.withOpacity(0.3),
                              isFilled: true),
                          Polygon(
                              points: [
                                LatLng(52.276120, 76.968639),
                                LatLng(52.264721, 76.969562),
                                LatLng(52.265116, 76.984582),
                                LatLng(52.257216, 76.985376),
                                LatLng(52.259533, 77.039621),
                                LatLng(52.237670, 77.039363),
                                LatLng(52.237670, 77.039363),
                                LatLng(52.247470, 76.965549),
                                LatLng(52.246206, 76.948898),
                                LatLng(52.274857, 76.933620)
                              ],
                              isFilled: true,
                              color: Colors.tealAccent.withOpacity(0.3))
                        ]),
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
  final Color color;
  Store(this.id, this.name, this.city, this.coordinates, this.color);
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

Widget _darkModeTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      -0.2126, -0.7152, -0.0722, 0, 255, // Red channel
      -0.2126, -0.7152, -0.0722, 0, 255, // Green channel
      -0.2126, -0.7152, -0.0722, 0, 255, // Blue channel
      0, 0, 0, 1, 0, // Alpha channel
    ]),
    child: tileWidget,
  );
}
