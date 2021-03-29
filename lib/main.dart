import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';
import './route/index.dart';
import './common/static/base_data.dart';
import './uitl/image_utils.dart';

void main() {
  runApp(new App());

  //设置状态栏属性
  SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  //init loading animation
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 30.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black38
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.blue
    ..userInteractions = true;
  // ..customAnimation = CustomAnimation();
}

GlobalKey<NavigatorState> navigatorKey =
    new GlobalKey<NavigatorState>(debugLabel: '_navigatorKey');

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // //预加载图片信息
    ImageUitls.loadPrecacheImages(BaseData.getMapDeviceImages(), context);
    // precacheImage(AssetImage("images/map/service.png"), context);

    debugPaintSizeEnabled = false;
    return MaterialApp(
        title: 'title',
        initialRoute: RouteConfig.initRouteName,
        // theme: ThemeConfig.themeData(),
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        onGenerateRoute: RouteConfig.onGenerateRoute,
        navigatorKey: navigatorKey);
  }
}
