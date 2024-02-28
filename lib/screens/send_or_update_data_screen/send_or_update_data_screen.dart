import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SendOrUpdateData extends StatefulWidget {
  final String name;
  final String age;
  final String email;
  final String id;

  const SendOrUpdateData({
    this.name = '',
    this.age = '',
    this.email = '',
    this.id = '',
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

  @override
  void initState() {
    nameController.text = widget.name;
    ageController.text = widget.age;
    emailController.text = widget.email;
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    emailController.dispose();
    locationController.dispose();
    super.dispose();
  }

  String location = '';

  Future<void> getLocation() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          location = 'Lat: ${position.latitude}, Lng: ${position.longitude}';
          locationController.text = location;
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
        title: Text(
          'Send Data',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20).copyWith(top: 60, bottom: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'e.g. Zeeshan'),
            ),
            SizedBox(height: 20),
            Text(
              'Age',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(hintText: 'e.g. 25'),
            ),
            SizedBox(height: 20),
            Text(
              'Email Address',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: 'e.g. zeerockyf5@gmail.com'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  onPressed: getLocation,
                  child: Text('GET LOCATION'),
                ),
              ],
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Location',
                enabled: false,
              ),
            ),
            SizedBox(height: 40),
            MaterialButton(
              onPressed: () async {
                setState(() {});
                if (nameController.text.isEmpty ||
                    ageController.text.isEmpty ||
                    emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fill in all fields')),
                  );
                } else {
                  final dUser = FirebaseFirestore.instance.collection('users').doc(widget.id.isNotEmpty ? widget.id : null);
                  String docID = '';
                  if (widget.id.isNotEmpty) {
                    docID = widget.id;
                  } else {
                    docID = dUser.id;
                  }
                  final jsonData = {
                    'name': nameController.text,
                    'age': int.parse(ageController.text),
                    'email': emailController.text,
                    'location': locationController.text,
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
              },
              minWidth: double.infinity,
              height: 50,
              color: Colors.red.shade400,
              child: showProgressIndicator
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Text(
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
}
