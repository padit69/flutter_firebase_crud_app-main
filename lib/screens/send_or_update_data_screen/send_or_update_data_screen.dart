import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

class SendOrUpdateData extends StatefulWidget {
  final String name;
  final String age;
  final String email;
  final String id;
  final String lat;
  final String long;

  const SendOrUpdateData({
    this.name = '',
    this.age = '',
    this.email = '',
    this.id = '',
    this.lat = '',
    this.long = '',
  });

  @override
  State<SendOrUpdateData> createState() => _SendOrUpdateDataState();
}

class _SendOrUpdateDataState extends State<SendOrUpdateData> {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  bool showProgressIndicator = false;

  MapController mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: true,
  ));

  @override
  void initState() {
    nameController.text = widget.name;
    ageController.text = widget.age;
    emailController.text = widget.email;
    locationController.text = '${widget.lat};${widget.long}';
    initMapForEdit();
    super.initState();
  }

  initMapForEdit() async {
    if (widget.lat.isNotEmpty && widget.long.isNotEmpty) {
      final lat = double.parse(widget.lat);
      final long = double.parse(widget.long);
      Future.delayed(Duration(milliseconds: 500), () async {
        await mapController
            .changeLocation(GeoPoint(latitude: lat, longitude: long));
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    emailController.dispose();
    locationController.dispose();
    mapController.dispose();
    super.dispose();
  }

  String location = '';

  Future<void> getLocation() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      try {
        geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        );
        setState(() async {
          location = '${position.latitude};${position.longitude}';
          locationController.text = location;
          await mapController.changeLocation(GeoPoint(
              latitude: position.latitude, longitude: position.longitude));
        });
      } catch (e) {
        print('Error getting location: $e');
        // Xử lý lỗi khi không thể lấy vị trí
      }
    } else {
      // Người dùng từ chối cấp quyền, bạn có thể hiển thị thông báo hoặc xử lý khác
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        title: const Text(
          'Send Data',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(horizontal: 20).copyWith(top: 60, bottom: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'e.g. Zeeshan'),
            ),
            SizedBox(height: 20),
            const Text(
              'Age',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(hintText: 'e.g. 25'),
            ),
            SizedBox(height: 20),
            const Text(
              'Email Address',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextField(
              controller: emailController,
              decoration:
                  InputDecoration(hintText: 'e.g. zeerockyf5@gmail.com'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  onPressed: getLocation,
                  child: Text('GET LOCATION'),
                ),
              ],
            ),
            Container(
              height: 200,
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
                      initZoom: 8,
                      minZoomLevel: 3,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
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
                          size: 48,
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
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                hintText: 'Location',
                enabled: false,
              ),
            ),
            SizedBox(height: 40),
            MaterialButton(
              onPressed: () async {
                await submitData(context);
              },
              minWidth: double.infinity,
              height: 50,
              color: Colors.red.shade400,
              child: showProgressIndicator
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> submitData(BuildContext context) async {
    setState(() {});
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fill in all fields')),
      );
    } else {
      final dUser = firebase.FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id.isNotEmpty ? widget.id : null);
      String docID = '';
      if (widget.id.isNotEmpty) {
        docID = widget.id;
      } else {
        docID = dUser.id;
      }

      final slipLocation = locationController.text.split(';');
      final locations = slipLocation.length == 2
          ? {"lat": slipLocation[0], "long": slipLocation[1]}
          : null;
      final jsonData = {
        'name': nameController.text,
        'age': int.parse(ageController.text),
        'email': emailController.text,
        'location': locations,
        'id': docID,
      };
      showProgressIndicator = true;
      if (widget.id.isEmpty) {
        await dUser.set(jsonData).then((value) {
          nameController.text = '';
          ageController.text = '';
          emailController.text = '';
          locationController.text = '';
          showProgressIndicator = false;
          setState(() {});
        });
      } else {
        await dUser.update(jsonData).then((value) {
          nameController.text = '';
          ageController.text = '';
          emailController.text = '';
          locationController.text = '';
          showProgressIndicator = false;
          setState(() {});
        });
      }
    }
  }
}
