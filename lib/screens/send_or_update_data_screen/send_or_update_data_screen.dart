import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_crud_app/screens/auth/auth_screen.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class AddressModel {
  String name;
  String street;
  String city;
  String country;
  String district;

  AddressModel(
      {this.name = "",
      this.street = "",
      this.district = "",
      this.city = "",
      this.country = ""});

  factory AddressModel.fromLocation(Placemark data) {
    return AddressModel(
        name: data.name ?? "",
        street: data.street ?? "",
        city: data.administrativeArea ?? "",
        district: data.subAdministrativeArea ?? "",
        country: data.country ?? "");
  }
  // Initialize AddressModel from a JSON map
  AddressModel.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? "",
        street = json['street'] ?? "",
        district = json['district'] ?? "",
        city = json['city'] ?? "",
        country = json['country'] ?? "";

  // Convert AddressModel to a JSON map
  Map<String, dynamic> toJson() => {
        'name': name,
        'street': street,
        'district': district,
        'city': city,
        'country': country,
      };
}

class UserData {
  String name;
  String age;
  String email;
  String id;
  String lat;
  String long;
  String imageURL;
  String createById;
  AddressModel? address;

  UserData(
      {this.name = "",
      this.age = "",
      this.email = "",
      this.id = "",
      this.lat = "",
      this.long = "",
      this.address,
      this.imageURL = "",
      this.createById = ""});

  factory UserData.fromFirestore(firebase.DocumentSnapshot? doc) {
    if (doc == null) return UserData();
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return UserData(
        name: data?['name'] ?? '',
        age: data?['age'] ?? '',
        email: data?['email'] ?? '',
        id: doc.id ?? "",
        lat: data?['lat'] ?? '',
        long: data?['long'] ?? '',
        address: AddressModel.fromJson(data?['address'] ?? {}),
        imageURL: data?['imageURL'] ?? '',
        createById: data?["createById"] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'email': email,
      'id': id,
      'lat': lat,
      'long': long,
      'imageURL': imageURL,
      'createById': createById,
      'address': address?.toJson()
    };
  }
}

class SendOrUpdateData extends StatefulWidget {
  final UserData userData;

  const SendOrUpdateData({super.key, required this.userData});

  @override
  State<SendOrUpdateData> createState() => _SendOrUpdateDataState();
}

class _SendOrUpdateDataState extends State<SendOrUpdateData> {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  var isLoading = false;

  loading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  MapController mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: true,
  ));

  @override
  void initState() {
    nameController.text = widget.userData.name;
    ageController.text = widget.userData.age;
    emailController.text = widget.userData.email;

    mapController.listenerMapSingleTapping.addListener(() {
      final point = mapController.listenerMapSingleTapping.value;
      if (point != null) {
        _selectPoint(point);
      }
    });
    initMapForEdit();
    super.initState();
  }

  initMapForEdit() async {
    if (widget.userData.lat.isNotEmpty && widget.userData.long.isNotEmpty) {
      final lat = double.parse(widget.userData.lat);
      final long = double.parse(widget.userData.long);
      locationLat = lat;
      locationLong = long;
      locationController.text = 'Vĩ độ: ${lat} Kinh độ:${long}';
      Future.delayed(Duration(milliseconds: 500), () async {
        await mapController
            .changeLocation(GeoPoint(latitude: lat, longitude: long));
      });
    }
  }

  _selectPoint(GeoPoint point) {
    mapController
        .removeMarker(GeoPoint(latitude: locationLat, longitude: locationLong));
    mapController.addMarker(point,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_history_rounded,
            color: Colors.red,
            size: 48,
          ),
        ));
    locationLat = point.latitude;
    locationLong = point.longitude;
    locationController.text =
        'Vĩ độ: ${point.latitude} Kinh độ:${point.longitude}';
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

  double locationLat = 0;
  double locationLong = 0;

  Future<void> getLocation() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      try {
        geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        );
        setState(() async {
          locationLat = position.latitude;
          locationLong = position.longitude;
          locationController.text =
              'Vĩ độ: ${position.latitude} Kinh độ:${position.longitude}';
          await mapController.changeLocation(GeoPoint(
              latitude: position.latitude, longitude: position.longitude));
        });
      } catch (e) {
        print('Error getting location: $e');
      }
    } else {}
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> _deleteImage(String docID) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child(docID + '.jpg');

      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      print('Error deleting image from Storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image')),
      );
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
      body: Container(
        child: Stack(
          children: [
            _renderContent(context),
            isLoading ? ProgressIndicatorExample() : Container(),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView _renderContent(BuildContext context) {
    return SingleChildScrollView(
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
            decoration: InputDecoration(hintText: 'Name'),
          ),
          SizedBox(height: 20),
          const Text(
            'Age',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextField(
            controller: ageController,
            decoration: InputDecoration(hintText: 'Age'),
          ),
          SizedBox(height: 20),
          const Text(
            'Email Address',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(hintText: 'Email'),
          ),
          SizedBox(height: 20),
          _image != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ảnh',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 10),
                    Image.file(_image!, height: 100),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _getImage,
                          child: Text('Chọn ảnh mới'),
                        ),
                      ],
                    ),
                  ],
                )
              : widget.userData.imageURL.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ảnh',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 10),
                        Image.network(
                          widget.userData.imageURL,
                          height: 100,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _getImage,
                              child: Text('Chọn ảnh mới'),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                _deleteImage(widget.userData.id);
                              },
                              style: ElevatedButton.styleFrom(),
                              child: Text('Xóa Url ảnh cũ'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _getImage,
                      child: Text('Chọn ảnh'),
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
            height: 300,
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
                    initZoom: 10,
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
            color: const Color.fromRGBO(239, 83, 80, 1),
            child: isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
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
    );
  }

  Future<void> submitData(BuildContext context) async {
    loading(true);
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hãy điền đầy đủ thông tin')),
      );
      loading(false);
    } else {
      final dUser = firebase.FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userData.id.isNotEmpty ? widget.userData.id : null);
      String docID = '';
      if (widget.userData.id.isNotEmpty) {
        docID = widget.userData.id;
      } else {
        docID = dUser.id;
      }

      AddressModel? andress;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(locationLat, locationLong);

      if (placemarks.isNotEmpty) {
        andress = AddressModel.fromLocation(placemarks.first);
      }

      final jsonData = UserData(
          createById: userLogin.id,
          name: nameController.text,
          age: ageController.text,
          email: emailController.text,
          lat: locationLat.toString(),
          address: andress,
          long: locationLong.toString(),
          id: docID);

      if (widget.userData.id.isNotEmpty) {
        jsonData.createById = widget.userData.createById;
      }

      final newImageURL = await _updateImage(_image, docID);
      if (newImageURL != null) {
        jsonData.imageURL = newImageURL;
      }

      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child(docID + '.jpg');

        await storageRef.putFile(_image!);

        final imageURL = await storageRef.getDownloadURL();
        jsonData.imageURL = imageURL;
      }
      if (widget.userData.id.isEmpty) {
        await dUser.set(jsonData.toJson()).then((value) {
          nameController.text = '';
          ageController.text = '';
          emailController.text = '';
          locationController.text = '';
          _image = null;
          setState(() {});
        });
      } else {
        await dUser.update(jsonData.toJson()).then((value) {
          nameController.text = '';
          ageController.text = '';
          emailController.text = '';
          locationController.text = '';
          setState(() {});
        });
      }
      loading(false);
    }
  }
}

Future<String?> _updateImage(File? newImage, String docID) async {
  if (newImage != null) {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child(docID + '.jpg');

      await storageRef.putFile(newImage);

      final imageURL = await storageRef.getDownloadURL();
      return imageURL;
    } catch (e) {
      print('Lỗi khi cập nhật ảnh lên Storage: $e');
      return null;
    }
  }

  return null;
}
