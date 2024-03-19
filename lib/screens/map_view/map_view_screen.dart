import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as Firebase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_firebase_crud_app/screens/send_or_update_data_screen/send_or_update_data_screen.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

  Future<void> loadHtmlFromAssets() async {
    try {
      String htmlString = await rootBundle.loadString('assets/index.html');
      print(htmlString);
      controller.loadHtmlString(htmlString);
    } catch (e) {
      print('Error loading HTML file: $e');
    }
  }

  initData() async {
    loadHtmlFromAssets();
    // Firebase.CollectionReference authRef =
    //     Firebase.FirebaseFirestore.instance.collection('users');
    // Firebase.QuerySnapshot querySnapshot = await authRef.get();
    // if (querySnapshot.docs.isNotEmpty) {
    //   final data =
    //       querySnapshot.docs.map((e) => UserData.fromFirestore(e)).toList();
    // }
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
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
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
