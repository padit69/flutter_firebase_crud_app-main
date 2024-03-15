import 'package:cloud_firestore/cloud_firestore.dart' as Firebase;
import 'package:flutter/material.dart';
import 'package:flutter_firebase_crud_app/screens/send_or_update_data_screen/send_or_update_data_screen.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: false,
  ));

  initData() async {
    Firebase.CollectionReference authRef =
        Firebase.FirebaseFirestore.instance.collection('users');
    Firebase.QuerySnapshot querySnapshot = await authRef.get();
    if (querySnapshot.docs.isNotEmpty) {
      final data =
          querySnapshot.docs.map((e) => UserData.fromFirestore(e)).toList();
      data.forEach((element) async {
        await mapController.addMarker(
          GeoPoint(
            latitude: double.parse(element.lat),
            longitude: double.parse(element.long),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () async {
      initData();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'MAP',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: SafeArea(
        child: OSMFlutter(
            controller: mapController,
            onLocationChanged: (p0) {
              print(p0);
            },
            onMapIsReady: (p0) {
              print('map is readly' + p0.toString());
            },
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 50,
                minZoomLevel: 8,
                maxZoomLevel: 19,
                stepZoom: 5.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    size: 60,
                  ),
                ),
              ),
              roadConfiguration: const RoadOption(
                roadColor: Colors.yellowAccent,
              ),
              markerOption: MarkerOption(
                  defaultMarker: const MarkerIcon(
                icon: Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 56,
                ),
              )),
            )),
      ),
    );
  }
}
