import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:intl/intl.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';
import 'package:police_mobile_sytem/request/api.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:police_mobile_sytem/component/input_dialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:police_mobile_sytem/component/jhPickerTool.dart';

import 'package:police_mobile_sytem/component/loading_dialog.dart';
import 'package:police_mobile_sytem/component/dialog_route.dart';

import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart';
import 'package:police_mobile_sytem/request/base_url.dart';

GlobalKey<_StaggedAnimationState> childTopBarKey =
    GlobalKey(debugLabel: '_StaggedAnimationState');

class StaggedAnimation extends StatefulWidget {
  //控制地图
  final AmapController mapController;
  //动画控制参数
  final Animation<double> controller;
  final Animation<double> bezier; //透明度渐变
  final Animation<EdgeInsets> drift; //位移变化

  StaggedAnimation({Key key, this.controller, this.mapController})
      : bezier = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        )),
        drift = EdgeInsetsTween(
          begin: const EdgeInsets.only(top: 0.0),
          end: const EdgeInsets.only(top: 100.0),
        ).animate(
          CurvedAnimation(
            parent: controller,
            // curve: Interval(0.375, 0.5, curve: Curves.ease),
            curve: Curves.easeInOut,
          ),
        ),
        super(key: key);

  @override
  _StaggedAnimationState createState() => _StaggedAnimationState();
}

class _StaggedAnimationState extends State<StaggedAnimation>
    with WidgetsBindingObserver {
  //控制地图
  AmapController mapController;
  //动画控制参数
  Animation<double> controller;
  Animation<double> bezier; //透明度渐变
  Animation<EdgeInsets> drift; //位移变化

  //消息通知
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  //预警图片
  Image warningImage;
  //已有预警正在处置状态
  bool isWarningOnDealing = false;
  //处置措施字典
  List dealDicIndex = new List();
  List dealDicName = new List();
  List dealDic = new List();
  int policingDelIndex;
  String policingDelName = '请选择';
  //定时间隔
  Duration period = const Duration(seconds: 60);
  //定时标识
  Map timerCache = {'meteo': null, 'policing': null};
  //上传图片区域高度
  double imageAreaHeight = 70.0;
  //图片上传后返回链接
  List imagesUrlList = new List();
  //图片上传转换后url
  List imagesTransforUrlList = new List();
  //warning数据缓存
  Map<String, List> _warningDataCache = {};
  //warning layers 数据缓存（markerOption）
  Map<String, List> _warningLayerCache = {};
  //warning layers 打到地图上的Marker 数据缓存
  Map<String, List> _warningMarkerCache = {};
  //创建Map{warningId-{data:{},markerOption:{},maker:{}}}的数据结构便于查找使用
  // Map<String, Map> _warningKeyValueCache = {};
  //预警操作图层，默认每次只能处理一个预警（markerOption缓存）
  Map<String, List> _warningDealingCache = {};
  //预警惭怍marker缓存
  Map<String, List> _warningDealingMarkerCache = {};
  //预警处置描述
  final TextEditingController _warningLogTextController =
      new TextEditingController();
  //警情处置措施
  final TextEditingController _dealStepTextController =
      new TextEditingController();
  //警情处理日志描述
  final TextEditingController _policingLogController =
      new TextEditingController();

  void requestPersmission() async {
    // await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    PermissionStatus permission = await Permission.contacts.status;
  }

  @override
  void initState() {
    // TODO: implement initState
    requestPersmission();
    super.initState();
    //监听组件变化
    // WidgetsBinding.instance.addObserver(this);
    mapController = widget.mapController;
    controller = widget.controller;
    bezier = widget.bezier;
    drift = widget.drift;
    //获取警情处置字典
    getDealDic();

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android: android, iOS: iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);

    warningImage = Image.asset(
      'images/warning_map.png',
      width: 20,
      height: 20,
    );
    // precacheImage(new AssetImage('images/warning_map.png'), context);
    // getMeteoWarning();
    // getPolicingWarning();
    //定时查询开启
    if (timerCache['meteo'] == null) {
      timerCache['meteo'] = new Timer.periodic(period, (timer) {
        getMeteoWarning('meteo', true);
        getPolicingWarning('policing', true);
        print('meteo' + 'timer start');
      });
    }

    // //定时查询开启
    // if (timerCache['policing'] == null) {
    //   timerCache['policing'] = new Timer.periodic(period, (timer) {
    //     getPolicingWarning('policing', true);
    //     print('policing timer start');
    //   });
    // }
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    timerCache['meteo']?.cancel();
    timerCache['meteo'] = null;
    timerCache['policing']?.cancel();
    timerCache['policing'] = null;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (this.mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(warningImage.image, context);
  }

  Future onSelectNotification(String payload) {
    // debugPrint("payload : $payload");
    showDialog(
      context: context,
      builder: (_) => new AlertDialog(
        title: Container(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              new Text(
                '消息通知',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                  child: Container(
                    child: Image.asset(
                      'images/close.png',
                      width: 20.0,
                      height: 20.0,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop())
            ])),
        content: new Text('$payload'),
      ),
    );
  }

  showNotification(type, message) async {
    // print('aaaaaaaa');
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.high, importance: Importance.max);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.show(
        0, '消息通知', '您有新的 ${message} 消息,请注意查收！', platform,
        payload: '您有新的 ${message} 消息,请注意查收！');
  }

  //预警图层图标
  var _warningLayers = {
    'meteo': {
      'id': 0,
      'name': '气象预警',
      'layerName': 'meteo',
      'layerType': 'warning_info',
      'isActive': false
    },
    'policing': {
      'id': 1,
      'name': '事故预警',
      'layerName': 'policing',
      'layerType': 'warning_info',
      'isActive': false
    },
    // // 检测使用
    // 'illegal': {
    //   'id': 2,
    //   'name': '违法预警',
    //   'layerName': 'illegal',
    //   'layerType': 'warning_info',
    //   'isActive': false
    // },
    // 'yd': {
    //   'id': 3,
    //   'name': '拥堵预警',
    //   'layerName': 'yd',
    //   'layerType': 'warning_info',
    //   'isActive': false
    // }
  };

  //获取警情处置字典
  getDealDic() async {
    var res = await RequestApi.getDealDic({});
    if (res != null) {
      dealDic = res.data['result']['rows'];
      if (dealDic.length > 0) {
        for (var i in dealDic) {
          dealDicIndex.add(i['codeNo']);
          dealDicName.add(i['codeName']);
        }
      }
    }
  }

  //数组对象查找(只提醒未签收的)
  findList(nameKey, list) {
    var obj;
    list.forEach((e) {
      if (e[nameKey] == '0') obj = e;
    });
    return obj;
  }

  //预警初始请求
  getMeteoWarning(type, timeFlag) async {
    //图层隐藏状态或者正在处置状态 则丢弃定时查询结果
    if ((!_warningLayers[type]['isActive'] && timeFlag) ||
        (_warningDealingCache[type] != null &&
            _warningDealingCache[type].length > 0 &&
            timeFlag)) {
      var resNotifiCation = await getMeteoWarningDate(timeFlag);
      if (resNotifiCation != null) {
        //判断有没有新预警
        List warningList = resNotifiCation.data['result']['rows'];
        var newWarning = findList('receiveStatus', warningList);
        if (newWarning != null) showNotification('meteo', '气象预警');
      }
      return;
    }
    if (_warningLayers[type]['isActive'] && !timeFlag) {
      //如果是隐藏图层 怎不需要请求资源
      handleLayersShow(type, timeFlag);
      //清除定时器
      return;
    }
    var res = await getMeteoWarningDate(timeFlag);
    if (res != null) {
      if (res.data['result']['rows'].length > 0) {
        var newWarningInfo =
            findList('receiveStatus', res.data['result']['rows']);
        if (newWarningInfo != null) showNotification('meteo', '气象预警');
      }
      //获取当前路由信息，判断是否跟新预警消息
      var tt = ModalRoute.of(context);
      print(tt);
      _warningDataCache['meteo'] = res.data['result']['rows'];
      createMarkOnMap('meteo', _warningDataCache['meteo']);
      handleLayersShow(type, timeFlag);
    }
  }

  getMeteoWarningDate(timeFlag) async {
    if (!timeFlag) {
      Future.delayed(Duration.zero, () {
        Navigator.push(context, DialogRouter(LoadingDialog(true)));
      });
    }

    DateTime now = DateTime.now();
    var formatterStart = DateFormat('yyyy-MM-dd 00:00:00');
    var formatterEnd = DateFormat('yyyy-MM-dd 23:59:59');
    //气象预警
    var params = {
      'endFlag': '1',
      'receiveStatus': '0,1', //未签收和处置中的
      'startTime': formatterStart.format(now),
      'endTime': formatterEnd.format(now)
    };
    var data = FormData.fromMap(params);
    var res = await RequestApi.getWarningInfo(data, !timeFlag);
    if (!timeFlag) {
      Navigator.of(context).pop();
    }
    return res;
  }

  //获取警情
  getPolicingWarning(type, timeFlag) async {
    //图层隐藏状态
    if ((!_warningLayers[type]['isActive'] && timeFlag) ||
        (_warningDealingCache[type] != null &&
            _warningDealingCache[type].length > 0 &&
            timeFlag)) {
      var resNotification = await getPolicingData(timeFlag);
      if (resNotification != null) {
        if (resNotification.data['result']['rows'].length > 0)
          showNotification('policing', '事件警情');
      }
      return;
    }
    if (_warningLayers[type]['isActive'] && !timeFlag) {
      //如果是隐藏图层 怎不需要请求资源
      handleLayersShow(type, timeFlag);
      return;
    }

    var resPolice = await getPolicingData(timeFlag);
    if (resPolice != null) {
      if (resPolice.data['result']['rows'].length > 0)
        showNotification('policing', '事件警情');
      _warningDataCache['policing'] = resPolice.data['result']['rows'];
      createMarkOnMap('policing', _warningDataCache['policing']);
      handleLayersShow(type, timeFlag);
    }
  }

  getPolicingData(timeFlag) async {
    if (!timeFlag) {
      Future.delayed(Duration.zero, () {
        Navigator.push(context, DialogRouter(LoadingDialog(true)));
      });
    }
    List userInfo =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    //未处理事故警情
    String url =
        '/ControlPlatform/service/trafficMonitor/trafficEvent/selectTrafficEventInfoHistory?currentOrgPrivilegeCode=' +
            userInfo[4] +
            '&handleState=0&eventType=16&pageNumber=1&pageSize=10';
    var resPolice = await RequestApi.getPolicingWaring(url, !timeFlag);
    if (!timeFlag) {
      Navigator.of(context).pop();
    }
    return resPolice;
  }

  //获取数据的同时缓存并打点
  createMarkOnMap(type, _warningData) async {
    //图层添加markOptions
    if (_warningLayerCache.containsKey(type) == false) {
      _warningLayerCache.addAll({type: <MarkerOption>[]});
      _warningMarkerCache.addAll({type: <Marker>[]});
    }

    //清除预警图层null
    if (_warningMarkerCache[type].length > 0) {
      await mapController.clearMarkers(_warningMarkerCache[type]);
    }

    _warningLayerCache[type]?.length = 0;
    _warningMarkerCache[type]?.length = 0;

    //判断显示还是隐藏操作
    if (_warningData != null && _warningData.length > 0) {
      //显示图层
      _warningData.map((e) {
        var options = createWarningMarkerOption(e, type);
        if (options != null) {
          _warningLayerCache[type].add(options);
        }
      }).toList();
    }
  }

  //createMarker
  createWarningMarkerOption(e, type) {
    if (e['longLat'] != null && e['longLat'].startsWith('Point') == true) {
      var longLatTemp = e['longLat']?.substring(6, e['longLat'].length - 1);
      e['longLatTemp'] = longLatTemp?.split(' ');
      if (double.parse(e['longLatTemp'][1]) >= -90.0 &&
          double.parse(e['longLatTemp'][1]) <= 90.0 &&
          double.parse(e['longLatTemp'][0]) >= -180.0 &&
          double.parse(e['longLatTemp'][0]) <= 180.0) {
        var option = MarkerOption(
            object: type == 'meteo'
                ? e['alarmId'] +
                    '_warning' +
                    '_meteo' +
                    '_${e["receiveStatus"]}' +
                    '_marker'
                : e['eventId'] +
                    '_warning' +
                    '_policing' +
                    '_${e["handleState"]}' +
                    '_marker',
            title: e['position'],
            snippet: type == 'meteo' ? e['position'] : e['eventId'],
            latLng: LatLng(double.parse(e['longLatTemp'][1]),
                double.parse(e['longLatTemp'][0])),
            infoWindowEnabled: false,
            visible: true,
            // iconProvider: AssetImage('images/warning_map.png'),
            widget: Container(
                child: GestureDetector(
              child: Column(children: [
                warningImage,
                Text(
                  e['position'],
                  style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.red,
                      decoration: TextDecoration.none),
                )
              ]),
              onTap: () => print('marker click'),
            )));
        return option;
      }
    } else if (e['longLat'] != null &&
        e['longLat'].startsWith('LineString') == true) {
      //预警线处理
      //经纬度数组
      String tempStr = e['longLat']?.substring(11, e['longLat'].length - 1);
      List temp = tempStr.split(',');
      List<LatLng> polyline = new List();
      //生成line
      for (int i = 0; i < temp.length; i++) {
        List tempLatLng = temp[i]?.split(' ');
        if (double.parse(tempLatLng[1]) >= -90.0 &&
            double.parse(tempLatLng[1]) <= 90.0 &&
            double.parse(tempLatLng[0]) >= -180.0 &&
            double.parse(tempLatLng[0]) <= 180.0) {
          polyline.add(
              LatLng(double.parse(tempLatLng[1]), double.parse(tempLatLng[0])));
        }
      }

      var lineOption = MarkerOption(
          object: type == 'meteo'
              ? e['alarmId'] +
                  '_warning' +
                  '_meteo' +
                  '_${e["receiveStatus"]}' +
                  '_marker'
              : e['eventId'] +
                  '_warning' +
                  '_policing' +
                  '_${e["handleState"]}' +
                  '_marker',
          title: e['position'],
          snippet: type == 'meteo' ? e['position'] : e['eventId'],
          latLng: polyline[0],
          infoWindowEnabled: false,
          visible: true,
          // iconProvider: AssetImage('images/warning_map.png'),
          widget: Container(
              child: GestureDetector(
            child: Column(children: [
              warningImage,
              Text(
                e['position'],
                style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.red,
                    decoration: TextDecoration.none),
              )
            ]),
            onTap: () => print('marker click'),
          )));

      return lineOption;
    }
  }

  //点击地图删除操作图层
  onMapClicked() async {
    if (_warningDealingMarkerCache != null) {
      //清除零一图层处理marker
      _warningDealingMarkerCache.forEach((key, value) async {
        if (_warningDealingMarkerCache[key] != null &&
            _warningDealingMarkerCache[key].length > 0) {
          await mapController?.clearMarkers(value);
          _warningDealingCache[key].length = 0;
        }
      });
    }
  }

  //预警、警情图层点击事件
  handleLayersClick(type) {
    if (type == '') return;
    if (type == "meteo") {
      //设备类
      getMeteoWarning(type, false);
    } else if (type == "policing") {
      //基础设施类
      getPolicingWarning(type, false);
    }
    //检测
    else if (type == "illegal") {
      showNotification('illegal', '车辆违法预警');
    } else if (type == "yd") {
      showNotification('yd', '拥堵预警');
    }
  }

  //点击预警图层操作Show
  handleLayersShow(String type, bool timerFlag) async {
    //区别定时器查询和手动查询
    if (!timerFlag) {
      //预警信息图层最多打开一个图层
      _warningLayers[type]['isActive'] = !_warningLayers[type]['isActive'];
    }

    //是否显示marker
    if (_warningLayers[type]['isActive']) {
      //先清空另一个图层
      String otherLayer = type == 'meteo' ? 'policing' : 'meteo';
      //判断另一图层 是否是打开状态 ，如果则隐藏
      if (_warningLayers[otherLayer]['isActive']) {
        _warningLayers[otherLayer]['isActive'] = false;
        if (_warningDealingMarkerCache[otherLayer] != null &&
            _warningDealingMarkerCache[otherLayer].length > 0) {
          //清除零一图层处理marker
          await mapController
              ?.clearMarkers(_warningDealingMarkerCache[otherLayer]);
          _warningDealingCache[otherLayer].length = 0;
        }
        //清除零一图层marker
        await mapController.clearMarkers(_warningMarkerCache[otherLayer]);
        _warningMarkerCache[otherLayer].length = 0;
      }

      if (_warningDealingMarkerCache[type] != null &&
          _warningDealingMarkerCache[type].length > 0) {
        await mapController.clearMarkers(_warningDealingMarkerCache[type]);
        _warningDealingCache[type].length = 0;
      }

      await mapController.clearMarkers(_warningMarkerCache[type]);
      _warningMarkerCache[type].length = 0;

      //地图打点
      var markers = await mapController.addMarkers(_warningLayerCache[type]);
      _warningMarkerCache[type] = markers;
    } else {
      if (_warningDealingMarkerCache[type] != null &&
          _warningDealingMarkerCache[type].length > 0) {
        await mapController.clearMarkers(_warningDealingMarkerCache[type]);
        _warningDealingCache[type].length = 0;
      }

      await mapController.clearMarkers(_warningMarkerCache[type]);
      _warningMarkerCache[type].length = 0;
    }

    setState(() {
      _warningLayers;
    });
  }

  //点击地图marker时响应方法
  onMarkerClicked(marker, info) {
    //先判断点击是预警marker还是操作marker
    if (info[1] == 'warning') {
      warningMarkerClicked(marker, info);
    } else if (info[1] == 'option') {
      optionMarkerClicked(marker, info);
    }
  }

  onOptionMarkerClick(marker, info) {
    optionMarkerClicked(marker, info);
  }

  //预警marker点击处理
  warningMarkerClicked(marker, info) async {
    String type = info[2];
    var option1, option2;
    //若是气象预警，则先在地图上展示确认有效无效的marker,点击确认有效，则请求后台接口更改预警状态展示处置日志和处置借宿按钮；若直接确认无效，则跟新状态；
    if (type == 'meteo') {
      //判断预警状态、缓存处理图层(若receiveStatus == 0，则是未签收状体，需要展示签收状态【1.有效，2无效】;若receiveStatus == 1，则是已签收状态，独赢展示处置日志相关信息)
      if (info[3] == '0') {
        //创建marker
        option1 =
            await createWarningOptionMarker(marker, info, '确认有效', 0.04, 0.02);
        option2 =
            await createWarningOptionMarker(marker, info, '确认无效', 0.04, -0.02);
      } else if (info[3] == '1') {
        //创建marker
        option1 =
            await createWarningOptionMarker(marker, info, '处置日志', 0.04, 0.02);
        option2 =
            await createWarningOptionMarker(marker, info, '处置结束', 0.04, -0.02);
      }
    }
    //若是警情则展示处置按钮
    else if (info[2] == 'policing') {
      //创建marker
      option1 = await createWarningOptionMarker(marker, info, '处置', 0.04, 0.02);
      option2 =
          await createWarningOptionMarker(marker, info, '取消', 0.04, -0.02);
    }
    //缓存marker 并打到地图
    markerToMap(type, option1, option2);
  }

  //操作marker点击处理
  optionMarkerClicked(marker, info) async {
    String text = await marker.title;
    //先判断是那种预警操作（info[3]）
    if (info[2] == 'meteo') {
      //在判断气象预警当前的状态（未签收和已签收状态，用）

      if (info[3] == '0') {
        //确认操作
        showOptionConfirmDialog(text, info, signWarning);
      } else if (info[3] == '1') {
        //判断操作类型
        if (text == '处置日志') {
          //新增处置日志操作
          showDealLogDialog('添加日志', info, saveDealLog);
        } else {
          //结束预警操作
          showOptionConfirmDialog(text, info, overWarning);
        }
      }
    } else if (info[2] == 'policing') {
      // String text = await marker.title;
      //判断操作类型
      if (text == '处置') {
        //警情处置
        showDealLogDialog('警情处置', info, savePolicingDealLog);
      } else {
        //处置结束操作
        cancelDealWaning(info, context, text);
      }
    }
  }

  //创建预警处理marker(param:预警marker信息，info,按钮展示信息)
  createWarningOptionMarker(marker, info, text, top, left) async {
    String type = info[2];
    //判断是否存在optionMarker
    if (_warningDealingCache[type] != null &&
        _warningDealingCache[type].length > 0) {
      await mapController.clearMarkers(_warningDealingMarkerCache[type]);
      _warningDealingCache[type].length = 0;
    }
    var latLng = await marker.location;
    double latitude = latLng.latitude + left;
    double longitude = latLng.longitude + top;
    String warningStatus = info[3];
    var objectIdTemp = await marker.object;
    var objectId = (objectIdTemp.split('_'))[0] +
        '_option' +
        '_${info[2]}' +
        '_${warningStatus}'; //(inf[2]->预警类型：meteo、policing)
    Widget optionWidget = Transform(
        transform: Matrix4.translationValues(0, 0, 0),
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0), color: Colors.blue),
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            // margin: EdgeInsets.fromLTRB(100.0, marginTop, 0, 20),
            child: GestureDetector(
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white,
                    decoration: TextDecoration.none),
              ),
              onTap: () => print(text),
            )));
    var option = MarkerOption(
        latLng: LatLng(latitude, longitude),
        object: objectId,
        infoWindowEnabled: false,
        title: text,
        widget: optionWidget);
    return option;
  }

  //操作打点到地图
  markerToMap(type, option1, option2) async {
    //图层添加markOptions
    if (_warningDealingCache.containsKey(type) == false) {
      _warningDealingCache.addAll({type: <MarkerOption>[]});
      _warningDealingMarkerCache.addAll({type: <Marker>[]});
    }
    //缓存marker 并打到地图
    _warningDealingCache[type].add(option1);
    _warningDealingCache[type].add(option2);
    //地图打点
    var markers = await mapController.addMarkers(_warningDealingCache[type]);

    _warningDealingMarkerCache[type] = markers;
  }

  //确认窗口
  Future<void> showOptionConfirmDialog(text, info, callbak) async {
    if (info[0] != null) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, _state) {
              var mediaQueryData = MediaQueryData.fromWindow(ui.window);
              return AnimatedContainer(
                color: Colors.transparent,
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.fromLTRB(
                    20.0, 0, 20.0, mediaQueryData.viewInsets.bottom + 20.0),
                child: Material(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('$text?',
                                style: TextStyle(fontSize: 16.0))),
                        Container(
                          height: 35.0,
                          padding: EdgeInsets.only(top: 0.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: Colors.black12, width: 1.0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                child: Text('取消'),
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              Container(
                                  height: 35.0,
                                  // padding: EdgeInsets.symmetric(horizontal: 40.0),
                                  child:
                                      VerticalDivider(color: Colors.black26)),
                              GestureDetector(
                                  child: Text(
                                    '确认',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  // onTap: () => signWarning(info, context, text))
                                  onTap: () => callbak(info, context, text))
                            ],
                          ),
                        )
                      ],
                    )),
                alignment: Alignment.center,
              );
            });
          });
    }
  }

  //图片窗口
  Future<void> showImageDialog(index) async {
    Map<String, String> headersMap = {
      'Authorization':
          await StorageUtil.getStringItem(Constants.StorageMap['token']) ?? null
    };
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, _state) {
            var mediaQueryData = MediaQueryData.fromWindow(ui.window);
            String url = imagesTransforUrlList[index];
            return AnimatedContainer(
              color: Colors.transparent,
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.fromLTRB(
                  20.0, 0, 20.0, mediaQueryData.viewInsets.bottom + 20.0),
              child: Material(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Image.network(
                          url,
                          headers: headersMap,
                        ),
                      ),
                      Container(
                        height: 35.0,
                        padding: EdgeInsets.only(top: 0.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: Colors.black12, width: 1.0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              child: Text('取消'),
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Container(
                                height: 35.0,
                                // padding: EdgeInsets.symmetric(horizontal: 40.0),
                                child: VerticalDivider(color: Colors.black26)),
                            GestureDetector(
                              child: Text(
                                '确认',
                                style: TextStyle(color: Colors.blue),
                              ),
                              // onTap: () => signWarning(info, context, text))
                              // onTap: () => callbak(info, context, text)
                            )
                          ],
                        ),
                      )
                    ],
                  )),
              alignment: Alignment.center,
            );
          });
        });
  }

  inputUnderline(color) {
    return UnderlineInputBorder(
        borderSide:
            BorderSide(width: 0.8, color: color, style: BorderStyle.solid));
  }

  List<Asset> images = List<Asset>();
  String _error = 'No Error Dectected';

  Widget buildGridView(callback) {
    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return Container(
            padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
            child: Stack(children: [
              GestureDetector(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: AssetThumb(
                      asset: asset,
                      width: 80,
                      height: 80,
                    ),
                  ),
                  onTap: () => showImageDialog(index)),
              Positioned(
                  left: 75.0,
                  top: 5.0,
                  child: GestureDetector(
                    child: Image.asset(
                      'images/delete.png',
                      width: 20.0,
                      height: 20.0,
                    ),
                    onTap: () => print('111'),
                  )),
            ]));
      }),
    );
  }

  deleteIamgeTemp(index, callback) {
    images.remove(images[index]);
    print(images.length);
    callback(() {
      images;
    });
  }

  List<Asset> resultList = List<Asset>();
  Future<void> loadAssets(callback) async {
    resultList.length = 0;
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 1,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#0088ff",
          actionBarTitle: "选择图片",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    // if (resultList.length > 0) {
    //   imageAreaHeight = 176.0;
    //   List images = (resultList == null) ? [] : resultList;

    //   Future.delayed(Duration.zero, () {
    //     Navigator.push(context, DialogRouter(LoadingDialog(true)));
    //   });
    //   // 上传照片时一张一张上传
    //   for (int i = 0; i < images.length; i++) {
    //     // 获取 ByteData
    //     ByteData byteData = await images[i].getByteData();
    //     List<int> imageData = byteData.buffer.asUint8List();

    //     MultipartFile multipartFile = MultipartFile.fromBytes(
    //       imageData,
    //       // 文件名
    //       filename: 'load_image.jpg',
    //       // 文件类型
    //       contentType: MediaType("image", "jpg"),
    //     );
    //     FormData formData = FormData.fromMap({
    //       // 后端接口的参数名称
    //       "file": multipartFile
    //     });
    //     // 使用 dio 上传图片
    //     var res = await RequestApi.uploadFile(formData);
    //     print(res);
    //     try {
    //       if (res.data != null && res.data[0] != null) {
    //         String urlTemp = '';
    //         List jsonMap = jsonDecode(res.data);
    //         if (jsonMap[0]['url'] != null) {
    //           List list = jsonMap[0]['url'].split('/');
    //           list[0] = BaseConfig.imageUrlConfig;
    //           urlTemp = list.join('/');
    //         }
    //         imagesUrlList.add(jsonMap[0]['url']);
    //         imagesTransforUrlList.add(urlTemp);
    //       }
    //     } catch (e) {}
    //   }

    //   Navigator.of(context).pop();
    // } else {
    //   imageAreaHeight = 70.0;
    // }

    if (resultList.length > 0) {
      imageAreaHeight = 176.0;
    } else {
      imageAreaHeight = 70.0;
    }

    callback(() {
      images = resultList;
      // imagesUrlList;
      // imagesTransforUrlList;
      imageAreaHeight = imageAreaHeight;
      _error = error;
    });
  }

  //上传图片
  showAddImage(callback) {
    imageAreaHeight = images.length > 0 ? 176.0 : 70.0;
    Widget uploadImageComponet = SizedBox(
      height: imageAreaHeight,
      child: Column(
        children: <Widget>[
          // Center(child: Text('Error: $_error')),
          Container(
              child: Row(children: [
            Container(
                padding: EdgeInsets.only(left: 12.0), child: Text('现场图片：')),
            RaisedButton(
              child: Text("选择图片(可不选)"),
              onPressed: () => loadAssets(callback),
            ),
          ])),
          Flexible(
              flex: 1,
              fit: FlexFit.tight,
              // child: buildGridView(callback),
              child: GridView.count(
                crossAxisCount: 3,
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
                children: List.generate(images.length, (index) {
                  Asset asset = images[index];
                  return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                      child: Stack(children: [
                        GestureDetector(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 10.0),
                              child: AssetThumb(
                                asset: asset,
                                width: 80,
                                height: 80,
                              ),
                            ),
                            onTap: () => showImageDialog(index)),
                        Positioned(
                            left: 75.0,
                            top: 5.0,
                            child: GestureDetector(
                              child: Image.asset(
                                'images/delete.png',
                                width: 20.0,
                                height: 20.0,
                              ),
                              onTap: () {
                                images.remove(images[index]);
                                print(images.length);
                                callback(() {
                                  images;
                                });
                              },
                            )),
                      ]));
                }),
              ))
        ],
      ),
    );

    return uploadImageComponet;
  }

  //处置日志
  Future<void> showDealLogDialog(String text, info, callbak) async {
    if (info[0] != null) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, _state) {
              // return child;
              // _warningLogTextController.text = '';
              var mediaQueryData = MediaQueryData.fromWindow(ui.window);
              return AnimatedContainer(
                color: Colors.transparent,
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.fromLTRB(
                    20.0, 0, 20.0, mediaQueryData.viewInsets.bottom + 20.0),
                child: Material(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          child: Text(text,
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w600)),
                        ),
                        text == '警情处置'
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 10.0),
                                child: Row(children: [
                                  Container(
                                      child: Text('处置措施：',
                                          style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w400))),
                                  Container(
                                      width: 200.0,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Text(
                                              policingDelName,
                                            ),
                                            FlatButton(
                                                height: 24.0,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 2.0),
                                                color: Colors.blue,
                                                highlightColor:
                                                    Colors.blue[700],
                                                colorBrightness:
                                                    Brightness.dark,
                                                splashColor: Colors.grey,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0)),
                                                onPressed: () {
                                                  JhPickerTool.showStringPicker(
                                                      context,
                                                      data: dealDicName,
                                                      clickCallBack:
                                                          (int index, var str) {
                                                    _state(() {
                                                      policingDelIndex = index;
                                                      policingDelName = str;
                                                    });
                                                    // print(index);
                                                    // print(str);
                                                  });
                                                },
                                                child: Text('点我选择',
                                                    style: TextStyle(
                                                        fontSize: 14.0,
                                                        fontWeight:
                                                            FontWeight.w100)))
                                          ],
                                        ),
                                      ))
                                ]))
                            : (text == "添加日志"
                                ? Container(
                                    padding: EdgeInsets.fromLTRB(
                                        40.0, 10.0, 10.0, 10.0),
                                    child: Row(children: [
                                      Container(child: Text('管制：')),
                                      Container(
                                          child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            child: Container(
                                              width: 50.0,
                                              height: 24.0,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      60, 179, 113, 1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0)),
                                              child: Text(
                                                '一级',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            onTap: () {
                                              _warningLogTextController.text =
                                                  '申请一级管制';
                                              // print(_warningLogTextController);
                                              _state(() {
                                                _warningLogTextController;
                                              });
                                            },
                                          ),
                                          GestureDetector(
                                            child: Container(
                                              width: 50.0,
                                              height: 24.0,
                                              margin:
                                                  EdgeInsets.only(left: 8.0),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      67, 143, 255, 1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0)),
                                              child: Text(
                                                '二级',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            onTap: () {
                                              _warningLogTextController.text =
                                                  '申请二级管制';
                                              _state(() {
                                                _warningLogTextController;
                                              });
                                            },
                                          ),
                                          GestureDetector(
                                            child: Container(
                                              width: 50.0,
                                              height: 24.0,
                                              margin:
                                                  EdgeInsets.only(left: 8.0),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      255, 69, 0, 1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0)),
                                              child: Text(
                                                '三级',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            onTap: () {
                                              _warningLogTextController.text =
                                                  '申请三级管制';
                                              _state(() {
                                                _warningLogTextController;
                                              });
                                            },
                                          )
                                        ],
                                      ))
                                    ]))
                                : Container()),
                        Container(
                            // margin: EdgeInsets.symmetric(
                            //   horizontal: 10.0,
                            // ),
                            padding:
                                EdgeInsets.fromLTRB(40.0, 10.0, 10.0, 10.0),
                            child: Row(children: [
                              Container(
                                  child: Text('描述：',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w400))),
                              Container(
                                  child: Expanded(
                                      child: TextField(
                                          controller: _warningLogTextController,
                                          maxLines: 3,
                                          minLines: 1,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.black12)),
                                            // labelText: '日志描述',
                                          ),
                                          style: TextStyle(fontSize: 14.0))))
                            ])),
                        text == "添加日志" ? showAddImage(_state) : Container(),
                        Container(
                          height: 35.0,
                          padding: EdgeInsets.only(top: 0.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: Colors.black12, width: 1.0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                child: Container(
                                    height: 50.0,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 6.0),
                                    child: Text('取消')),
                                onTap: () {
                                  _warningLogTextController.text = '';
                                  //上传图片缓存清空
                                  imagesUrlList.length = 0;
                                  // imagesTransforUrlList.length = 0;
                                  images.length = 0;
                                  resultList.length = 0;
                                  _state(() {
                                    policingDelIndex = null;
                                    policingDelName = '请选择';
                                    _warningLogTextController;
                                    images;
                                    resultList;
                                    imagesUrlList;
                                    // imagesTransforUrlList;
                                  });

                                  Navigator.of(context).pop();
                                },
                              ),
                              Container(
                                  height: 50.0,
                                  // padding: EdgeInsets.symmetric(horizontal: 40.0),
                                  child:
                                      VerticalDivider(color: Colors.black26)),
                              GestureDetector(
                                  child: Container(
                                      height: 50.0,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 6.0),
                                      child: Text(
                                        '确认',
                                        style: TextStyle(color: Colors.blue),
                                      )),
                                  // onTap: () => signWarning(info, context, text))
                                  onTap: () async {
                                    await callbak(info, context, text);
                                    if (policingDelIndex != null ||
                                        _warningLogTextController.text != '') {
                                      _warningLogTextController.text = '';
                                      //上传图片缓存清空
                                      imagesUrlList.length = 0;
                                      // imagesTransforUrlList.length = 0;
                                      _state(() {
                                        policingDelIndex = null;
                                        policingDelName = '请选择';
                                        _warningLogTextController;
                                        imagesUrlList;
                                        // imagesTransforUrlList;
                                      });
                                    }
                                  })
                            ],
                          ),
                        )
                      ],
                    )),
                alignment: Alignment.center,
              );
            });
          });
    }
  }

  //根据id 找 marker 和 markerOption
  dealMarker(type, id, receiveStatus) async {
    //更新data缓存
    var newDate;
    _warningDataCache[type].map((e) {
      if (id == e['alarmId']) {
        e['receiveStatus'] = receiveStatus;
        newDate = e;
      }
    }).toList();

    //marker
    for (int i = _warningMarkerCache[type].length - 1; i >= 0; i--) {
      String markerOptionInfo = await _warningMarkerCache[type][i].object;
      String markerOptionId = markerOptionInfo.split('_')[0];
      if (markerOptionId == id) {
        //清除此预警marker
        await mapController.clearMarkers([_warningMarkerCache[type][i]]);
        //清除预警缓存marker;
        _warningMarkerCache[type].remove(_warningMarkerCache[type][i]);
        // _warningLayerCache[type].remove(_warningLayerCache[type][i]);
      }
    }

    //marker options
    for (int i = _warningLayerCache[type].length - 1; i >= 0; i--) {
      String markerOptionInfo = await _warningLayerCache[type][i].object;
      String markerOptionId = markerOptionInfo.split('_')[0];
      if (markerOptionId == id) {
        _warningLayerCache[type].remove(_warningLayerCache[type][i]);
        //如果是预警结束则不需要重新打此点到地图
        if (receiveStatus == '') return;
        if (newDate != null && receiveStatus == '1') {
          var options = createWarningMarkerOption(newDate, type);
          if (options != null) {
            var markers;
            _warningLayerCache[type].add(options);
            markers = await mapController.addMarker(options);
            _warningMarkerCache[type].add(markers);
          }
        }
      }
    }
    //更新markerOption缓存
    // //更新marker
    // for (int i = 0; i < _warningDataCache[type].length; i++) {
    //   if (id == _warningDataCache[type][i]['alarmId'])
    //     _warningDataCache[type][i]['receiveStatus'] = 1;
    // }
  }

  //处理完警情后删除marker
  removePoclingMarker(type, id) async {
    //marker
    for (int i = _warningMarkerCache[type].length - 1; i >= 0; i--) {
      String markerOptionInfo = await _warningMarkerCache[type][i].object;
      String markerOptionId = markerOptionInfo.split('_')[0];
      if (markerOptionId == id) {
        //清除此预警marker
        await mapController.clearMarkers([_warningMarkerCache[type][i]]);
        //清除预警缓存marker;
        _warningMarkerCache[type].remove(_warningMarkerCache[type][i]);
        // _warningLayerCache[type].remove(_warningLayerCache[type][i]);
      }
    }
  }

  //确认有效操作(签收)
  signWarning(info, context, sign) async {
    String warningId = info[0];
    String type = info[2];
    List<String> uesrInfo =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    String receiveStatus = sign == "确认有效" ? '1' : '2';
    var param = {
      'id': warningId,
      'receiveStatus': receiveStatus,
      'currentUserId': uesrInfo[0]
    };
    var data = FormData.fromMap(param);
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    var res = await RequestApi.signWarning(data);
    Navigator.of(context).pop();
    if (res != null) {
      // 删除操作marker 地图marker变成可点击状态
      await mapController.clearMarkers(_warningDealingMarkerCache[type]);
      _warningDealingCache[type].length = 0;
      //跟新预警marker
      dealMarker(info[2], warningId, receiveStatus);
      Navigator.of(context).pop();
    }
  }

  //预警处理日志保存
  saveDealLog(info, context, text) async {
    //有图片则先上传图片
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    imagesUrlList.length = 0;
    if (resultList.length > 0) {
      List images = (resultList == null) ? [] : resultList;
      List<Future> formDataTemp = new List<Future>();
      List<FormData> formDataList = new List<FormData>();
      List res1 = new List();
      // 上传照片时一张一张上传
      for (int i = 0; i < images.length; i++) {
        // 获取 ByteData
        // ByteData byteData = await images[i].getByteData();
        ByteData byteData = await images[0].requestOriginal(quality: 10);
        List<int> imageData = byteData.buffer.asUint8List();

        MultipartFile multipartFile = MultipartFile.fromBytes(
          imageData,
          // 文件名
          filename: 'load_image${i.toString()}.jpg',
          // 文件类型
          contentType: MediaType("image", "jpg"),
        );
        String fileString = "file" + i.toString();
        FormData formData = FormData.fromMap({
          // 后端接口的参数名称
          fileString: multipartFile
        });

        // formDataTemp.add(RequestApi.uploadFile(formData));
        formDataList.add(formData);
        // // 使用 dio 上传图片
        // var res1 = await RequestApi.uploadFile(formData);

        // if (res1 != null && res1.data != null) {
        //   List jsonMap = await jsonDecode(res1.data);
        //   if (jsonMap != null &&
        //       jsonMap.length > 0 &&
        //       jsonMap[0] != null &&
        //       jsonMap[0]['url'] != null) {
        //     imagesUrlList.add(jsonMap[0]['url']);
        //   }
        // }
      }

      switch (formDataList.length) {
        case 1:
          res1 = await Future.wait([RequestApi.uploadFile(formDataList[0])]);
          break;
        case 2:
          res1 = await Future.wait([
            RequestApi.uploadFile(formDataList[0]),
            RequestApi.uploadFile(formDataList[1])
          ]);
          break;
        case 3:
          res1 = await Future.wait([
            RequestApi.uploadFile(formDataList[0]),
            RequestApi.uploadFile(formDataList[1]),
            RequestApi.uploadFile(formDataList[2])
          ]);
          break;
        default:
      }

      // List res1 = await Future.wait(formDataTemp);
      // Future.wait(formDataTemp).then((List response) => print(response));

      // List res1 = new List();
      print(res1);
      // return;
      for (int m = 0; m < res1.length; m++) {
        if (res1[m] != null && res1[m].data != null) {
          List jsonMap = await jsonDecode(res1[m].data);
          if (jsonMap != null &&
              jsonMap.length > 0 &&
              jsonMap[0] != null &&
              jsonMap[0]['url'] != null) {
            imagesUrlList.add(jsonMap[0]['url']);
          }
        }
      }
    }

    String type = info[2];
    //判断日志填写是否为空
    if (_warningLogTextController != null &&
        _warningLogTextController.text != null &&
        _warningLogTextController.text != '') {
      List<String> uesrInfo =
          await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
      String uploadUrl = imagesUrlList.join(',');
      var param = {
        'alarmId': info[0],
        'pushFlag': '2',
        'remark': _warningLogTextController.text,
        'currentUserId': uesrInfo[0],
        'isFromApp': '1', //'1'标识手机端提交
        'images': uploadUrl
      };
      var data = FormData.fromMap(param);
      // Future.delayed(Duration.zero, () {
      //   Navigator.push(context, DialogRouter(LoadingDialog(true)));
      // });
      var res = await RequestApi.addWarningLog(data);
      Navigator.of(context).pop();
      if (res != null) {
        // 删除操作marker 地图marker变成可点击状态
        await mapController.clearMarkers(_warningDealingMarkerCache[type]);
        _warningDealingCache[type].length = 0;
        resultList.length = 0;
        images.length = 0;
        setState(() {
          resultList;
          images;
        });
        Navigator.of(context).pop();
      }
    }
  }

  //结束预警
  overWarning(info, context, sign) async {
    // Navigator.of(context).pop();
    String warningId = info[0];
    String type = info[2];
    List<String> uesrInfo =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    var param = {'id': warningId, 'currentUserId': uesrInfo[0]};
    var data = FormData.fromMap(param);
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    var res = await RequestApi.overWarning(data);
    Navigator.of(context).pop();
    if (res != null) {
      // 删除操作marker 地图marker变成可点击状态
      await mapController.clearMarkers(_warningDealingMarkerCache[type]);
      _warningDealingCache[type].length = 0;
      //跟新预警marker
      dealMarker(info[2], warningId, '');
      Navigator.of(context).pop();
    }
  }

  //预警处置日志
  meteoWarningDealLog(text, data, context) {}
  //警情处置日志
  savePolicingDealLog(info, context, text) async {
    String type = info[2];
    //判断日志填写是否为空
    if (_warningLogTextController != null &&
        _warningLogTextController.text != null &&
        _warningLogTextController.text != '' &&
        policingDelIndex != null) {
      List<String> uesrInfo =
          await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
      var param = {
        'eventId': info[0],
        'progressConfigId': policingDelIndex,
        'progressConfigName': policingDelName,
        'progressRemark': _warningLogTextController.text,
        'progressUserId': uesrInfo[0],
        'progressUserName': uesrInfo[2],
        'approveResult': policingDelIndex == 0 ? '0' : '1',
      };
      var data = FormData.fromMap(param);
      Future.delayed(Duration.zero, () {
        Navigator.push(context, DialogRouter(LoadingDialog(true)));
      });
      var res = await RequestApi.addPolicingLog(data);
      Navigator.of(context).pop();
      if (res != null) {
        // 删除操作marker 地图marker变成可点击状态
        await mapController.clearMarkers(_warningDealingMarkerCache[type]);
        _warningDealingCache[type].length = 0;
        removePoclingMarker(type, info[0]);
        setState(() {
          policingDelIndex = null;
          policingDelName = '';
        });
        Navigator.of(context).pop();
      }
    }
  }

  //预警处置结束(预警)
  warningDealOver(data, context) {}
  //警情取消处置
  cancelDealWaning(info, context, text) async {
    String type = info[2];
    await mapController.clearMarkers(_warningDealingMarkerCache[type]);
    _warningDealingCache[type].length = 0;
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    //退出
    logout() async {
      Navigator.pushReplacementNamed(context, '/login');
    }

    return Transform(
        transform: Matrix4.translationValues(0, -50, 0),
        child: Container(
          padding: drift.value,
          alignment: Alignment.topCenter,
          child: Opacity(
            //透明组件
            opacity: bezier.value,
            child: Container(
              alignment: Alignment.topRight,
              // margin: EdgeInsets.fromLTRB(0, 40.0, 0.0, 0),
              // child: Image.asset('images/logout'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.topRight,
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 4.0,
                            color: Color.fromRGBO(0, 0, 0, .20))
                      ],
                      borderRadius: BorderRadius.circular(4.0),
                      color: Colors.white,
                    ),
                    child: GestureDetector(
                        child: Image.asset(
                          'images/logout.png',
                          width: 20.0,
                          height: 20.0,
                        ),
                        onTap: logout),
                  ),
                  Container(
                      alignment: Alignment.topRight,
                      width: 36.0,
                      height: 80.0,
                      // height: 160.0, //检测
                      margin: EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 4.0,
                              color: Color.fromRGBO(0, 0, 0, .20))
                        ],
                        borderRadius: BorderRadius.circular(4.0),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                              child: GestureDetector(
                            child: Image.asset(
                              'images/${_warningLayers['meteo']['layerName']}${_warningLayers['meteo']['isActive'] ? '_active' : ''}.png',
                              width: 20.0,
                              height: 20.0,
                            ),
                            onTap: () => handleLayersClick('meteo'),
                          )),
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.0, vertical: 0.0),
                              child: Divider(
                                height: 2.0,
                                thickness: 0.8,
                                color: Color(0xffD5D5D5),
                              )),
                          Container(
                              child: GestureDetector(
                            child: Image.asset(
                              'images/${_warningLayers['policing']['layerName']}${_warningLayers['policing']['isActive'] ? '_active' : ''}.png',
                              width: 20.0,
                              height: 20.0,
                            ),
                            onTap: () => handleLayersClick('policing'),
                            // onTap: () => showNotification('meteo', 'test'),
                          )),
                          // //检测
                          // Container(
                          //     child: GestureDetector(
                          //   child: Image.asset(
                          //     'images/${_warningLayers['illegal']['layerName']}${_warningLayers['illegal']['isActive'] ? '_active' : ''}.png',
                          //     width: 20.0,
                          //     height: 20.0,
                          //   ),
                          //   onTap: () => handleLayersClick('illegal'),
                          //   // onTap: () => showNotification('meteo', 'test'),
                          // )),
                          // Container(
                          //     child: GestureDetector(
                          //   child: Image.asset(
                          //     'images/${_warningLayers['yd']['layerName']}${_warningLayers['yd']['isActive'] ? '_active' : ''}.png',
                          //     width: 20.0,
                          //     height: 20.0,
                          //   ),
                          //   onTap: () => handleLayersClick('yd'),
                          //   // onTap: () => showNotification('meteo', 'test'),
                          // )),
                        ],
                      ))
                ],
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AnimatedBuilder(
      builder: _buildAnimation,
      animation: controller,
    );
  }
}
