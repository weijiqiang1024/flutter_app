import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../page/login.dart';
import '../page/home/home.dart';
import '../page/warning/index.dart';
import '../page/report/index.dart';

class RouteConfig {
  static final initRouteName = '/';

  static final Map<String, WidgetBuilder> router = {
    '/': (BuildContext context) => Login(),
    '/login': (BuildContext context) => Login(),
    '/home': (BuildContext context, {arguments}) =>
        CreateMapScreen(arguments: arguments),
    '/warning': (BuildContext context) => Warning(),
    '/reporting': (BuildContext context) => Reporting(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // 统一处理路由
    final String name = settings.name;
    final Function pageContentBuilder = router[name];

    //定义当前需要返回得route对象
    Route route;
    if (pageContentBuilder != null) {
      if (settings.arguments != null) {
        //带参数的处理方式
        switch (name) {
          default:
            route = CupertinoPageRoute(
                builder: (context) =>
                    pageContentBuilder(context, arguments: settings.arguments));
            break;
        }
      } else {
        //不带参数的处理方式
        switch (name) {
          case '/login':
            route = CupertinoPageRoute(
                builder: (context) =>
                    FlutterEasyLoading(child: pageContentBuilder(context)),
                fullscreenDialog: true);
            break;
          default:
            route = CupertinoPageRoute(
                builder: (context) =>
                    FlutterEasyLoading(child: pageContentBuilder(context)),
                fullscreenDialog: true);
            break;
        }
      }
    }
    return route;
  }
}
