import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CreateMapScreen(),
    );
  }
}

class CreateMapScreen extends StatefulWidget {
  @override
  _CreateMapScreenState createState() => _CreateMapScreenState();
}

class _CreateMapScreenState extends State<CreateMapScreen> {
  AmapController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('自定义地图')),
      body: AmapView(
        // 地图类型 (可选)
        mapType: MapType.Standard,
        // 缩放级别 (可选)
        zoomLevel: 10,
        // 中心点坐标 (可选)
        centerCoordinate: LatLng(33.956264, 116.798362),
        onMapCreated: (controller) async {
          _controller = controller;
          _controller.showTraffic(true);
           
        },
      ),
    );
  }
}
