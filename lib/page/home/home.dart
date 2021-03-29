// import 'package:flutter/cupertino.dart';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'dart:async';
import 'package:police_mobile_sytem/common/eventbus/EventBusManage.dart';
import 'package:police_mobile_sytem/common/eventbus/EventParam.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'bottomBar.dart';
import 'topBar.dart';
import 'zoomMap.dart';

import 'package:police_mobile_sytem/request/api.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';

class Home extends StatelessWidget {
  const Home({Key key, String data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String name = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      body: new SingleChildScrollView(
        child: new ConstrainedBox(
            constraints: new BoxConstraints(minHeight: 120.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: new BoxDecoration(color: Colors.white),
              child: Center(child: CreateMapScreen()),
            )),
      ),
    );
  }
}

class CreateMapScreen extends StatefulWidget {
  CreateMapScreen({this.arguments});
  final Map arguments;

  @override
  _CreateMapScreenState createState() =>
      _CreateMapScreenState(arguments: arguments);
}

class _CreateMapScreenState extends State<CreateMapScreen>
    with TickerProviderStateMixin {
  Map arguments;
  _CreateMapScreenState({this.arguments});
  //地图控制类
  AmapController _controller;
  //动画控制类
  AnimationController _animationController;

  //动画控制类
  AnimationController _animationControllerBottomPanel;

  //动画控制类
  AnimationController _videoPanelAnimationController;

  StreamSubscription _subscription;
  //地图点击标记(0->初始显示；1->隐藏)
  bool _mapClickStatus = false;
  //预警图层标识（meoto->气象、policing->事故警情）
  String _warningLayerType = 'meoto';
  //地图图层数据
  Map<String, List> _layers = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    //图层面板控制
    _animationControllerBottomPanel = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _videoPanelAnimationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _mapClickStatus = true;

    // //监听登录事件
    _subscription = eventBus.on<EventParam>().listen((EventParam data) =>
        // show(data.name)
        print(data.name));
    _subscription.resume();
    //显示动画
    _playAnimation(_mapClickStatus);
    // _getInitData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _subscription.cancel();
    //销毁动画
    _animationController.dispose();
    _animationControllerBottomPanel.dispose();
    _videoPanelAnimationController.dispose();
  }

  //点击地图面板动画
  Future<void> _playAnimation(status) async {
    print("22222");
    try {
      if (status) {
        await _animationController.forward().orCancel; //开始
      } else {
        await _animationController.reverse().orCancel; //反向
      }
    } on TickerCanceled {}
  }

  //请求图层数据
  _getInitData() async {
    var deviceType = [
      {'code': '03', 'name': 'video'},
      {'code': '06', 'name': 'speed_limit'},
      {'code': '07', 'name': 'screen'},
      {'code': '24', 'name': 'fog'}
    ];

    List<String> orgCodeList =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);

    for (var i = 0; i < deviceType.length; i++) {
      var params = {
        "deviceType": deviceType[i]['code'],
        "orgPrivilegeCode": orgCodeList[4]
      };
      try {
        var response = await RequestApi.getDeviceInfo(params);
        var res = response.data;
        if (res != null) {
          _layers[deviceType[i]['name']] = res;
        }
      } catch (e) {}

      if (i == deviceType.length - 1) {
        _getRoadFlagData(_layers);
      }
    }

    // _getRoadFlagData(_layers);
  }

  //道路桥梁
  _getRoadFlagData(_layers) async {
    var buildingType = [
      {'name': 'bridge', 'url': 'RequestApi.getBridgeDataInfo'},
      {'name': 'tunnel', 'url': 'RequestApi.getTunnelInfo'},
      {'name': 'toll_station', 'url': 'RequestApi.getTollGateInfo'},
      {'name': 'service', 'url': 'RequestApi.getServiceAreaInfo'},
      {'name': 'pivot', 'url': 'RequestApi.getPivotInfo'}
    ];
    EasyLoading.show(status: 'loading...');
    List temp = [];
    //桥梁
    try {
      var resB = await RequestApi.getBridgeDataInfo();
      temp.add(resB);
    } catch (e) {
      print('桥梁请求失败');
    }

    try {
      var resT = await RequestApi.getTunnelInfo();
      temp.add(resT);
    } catch (e) {
      print('隧道请求失败');
    }

    try {
      var resTG = await RequestApi.getTollGateInfo();
      temp.add(resTG);
    } catch (e) {
      print('请收费站求失败');
    }

    try {
      var resS = await RequestApi.getServiceAreaInfo();
      temp.add(resS);
    } catch (e) {
      print('服务区请求失败');
    }

    try {
      var resP = await RequestApi.getPivotInfo();
      //枢纽数据格式跟其他几个不同需要处理
      temp.add(resP);
    } catch (e) {
      print('枢纽请求失败');
    }

    Future.delayed(Duration(seconds: 2), () {
      EasyLoading.dismiss();
    });

    for (var m = 0; m < temp.length; m++) {
      if (temp[m].data != null) {
        //数据格式转换
        try {
          if (temp[m].data.isNotEmpty) {
            List mapTemp = new List();
            temp[m].data.map((e) {
              Map mapTempItem = {};
              mapTempItem['siteName'] = e[0];
              mapTempItem['siteLongitude'] =
                  (buildingType[m]['name'] == 'pivot') ? e[2] : e[1];
              mapTempItem['siteLatitude'] =
                  (buildingType[m]['name'] == 'pivot') ? e[3] : e[2];
              mapTemp.add(mapTempItem);
            }).toList();
            _layers[buildingType[m]['name']] = mapTemp;
          } else {
            _layers[buildingType[m]['name']] = temp[m].data;
          }
        } catch (e) {
          print(e.error);
        }
      }
    }

    //setState
    setState(() {
      _layers;
    });
  }

  // //生成地图覆盖物
  // _createMarkOption() {

  // }

  //监听地图点击事件
  _onMapClicked(controller) async {
    // print(childBottomKey);
    // debugger();
    //判断图层面板打开状态 已打开则先关闭图层面板
    if (childBottomKey.currentState != null &&
        childBottomKey.currentState.getPanelStatus() == true) {
      childBottomKey.currentState.showLayerPanel();
      return;
    }
    //这里要判断 当前的 bottomBar的状态
    _mapClickStatus = !_mapClickStatus;
    _playAnimation(_mapClickStatus);
    //点击地图清除操作图层
    if (childTopBarKey.currentState == null) return;
    childTopBarKey.currentState.onMapClicked();
  }

  _onMarkerClicked(marker) async {
    String objectId = await marker.object;
    // LatLng lnglat = await marker.location;
    String markerType;
    if (objectId == null || objectId == '') return;
    await _controller.setZoomLevel(11.0);
    // await _controller.setCenterCoordinate(lnglat);
    List info = objectId.split('_');
    markerType = info[1];
    switch (markerType) {
      case 'warning': //预警
        if (childTopBarKey.currentState == null) return;
        childTopBarKey.currentState.onMarkerClicked(marker, info);
        break;
      case 'option': //预警
        if (childTopBarKey.currentState == null) return;
        childTopBarKey.currentState.onOptionMarkerClick(marker, info);
        break;
      case 'device':
        if (childBottomKey.currentState == null) return;
        childBottomKey.currentState.onDeviceMarkerClick(marker, info);
        break;
      default:
    }

    print(objectId);
    // print(visible);
  }

  @override
  Widget build(BuildContext context) {
    //等待地图加载
    // init
    return Stack(
        // appBar: AppBar(title: const Text('自定义地图')),
        alignment: AlignmentDirectional.topCenter,
        children: <Widget>[
          //地图
          AmapView(
            // 地图类型 (可选)
            mapType: MapType.Standard,
            // 缩放级别 (可选)
            zoomLevel: 10,
            //地图放缩控件显示
            showZoomControl: false,
            // 中心点坐标 (可选)
            centerCoordinate: LatLng(33.956264, 116.798362),
            onMapCreated: (controller) async {
              _controller = controller;
              // _controller.setMapRegionLimits(
              //     LatLng(115.832147, 33.430717), LatLng(117.618798, 34.443576));
              _controller.showTraffic(true);
              // _controller.showTraffic(false); //检测
              setState(() {
                _controller;
              });
            },
            onMapClicked: (controller) async {
              _onMapClicked(controller);
            },
            onMarkerClicked: (marker) async {
              _onMarkerClicked(marker);
            },
          ),
          //上方操作面板
          _controller != null
              ? StaggedAnimation(
                  key: childTopBarKey,
                  controller: _animationController.view,
                  mapController: _controller)
              : new Container(),
          _controller != null
              ? ZoomStaggedAnimation(
                  controller: _animationController.view,
                  mapController: _controller)
              : new Container(),
          _controller != null
              ? MenuStaggedAnimation(
                  key: childBottomKey,
                  controller: _animationController.view,
                  mapController: _controller,
                  animationControllerBottomPanel:
                      _animationControllerBottomPanel.view,
                  videoPanelAnimationController:
                      _videoPanelAnimationController.view,
                  layersData: _layers)
              : new Container(),

          //下方操作面板
        ]);
  }
}
