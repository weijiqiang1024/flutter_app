import 'package:flutter/material.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:intl/intl.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';
import 'package:police_mobile_sytem/request/api.dart';

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

class _StaggedAnimationState extends State<StaggedAnimation> {
  //控制地图
  AmapController mapController;
  //动画控制参数
  Animation<double> controller;
  Animation<double> bezier; //透明度渐变
  Animation<EdgeInsets> drift; //位移变化

  //预警图片
  Image warningImage;
  //已有预警正在处置状态
  bool isWarningOnDealing = false;

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mapController = widget.mapController;
    controller = widget.controller;
    bezier = widget.bezier;
    drift = widget.drift;

    warningImage = Image.asset(
      'images/warning_map.png',
      width: 20,
      height: 20,
    );
    // precacheImage(new AssetImage('images/warning_map.png'), context);
    getMeteoWarning();
    getPolicingWarning();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(warningImage.image, context);
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
    }
  };

  //预警初始请求
  getMeteoWarning() async {
    DateTime now = DateTime.now();
    var formatterStart = DateFormat('yy-MM-dd 00:00:00');
    var formatterEnd = DateFormat('yy-MM-dd 23:59:59');
    //气象预警
    var params = {
      'endFlag': '1',
      'receiveStatus': '0,1', //未签收和处置中的
      'startTime': formatterStart.format(now),
      'endTime': formatterEnd.format(now)
    };
    var res = await RequestApi.getWarningInfo(params);
    if (res != null) {
      _warningDataCache['meteo'] = res.data['result']['rows'];
      createMarkOnMap('meteo', _warningDataCache['meteo']);
    }
  }

  //获取警情
  getPolicingWarning() async {
    List userInfo =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    //未处理事故警情
    String url =
        '/ControlPlatform/service/trafficMonitor/trafficEvent/selectTrafficEventInfoHistory?currentOrgPrivilegeCode=' +
            userInfo[4] +
            '&handleState=0&eventType=16&pageNumber=1&pageSize=10';
    var resPolice = await RequestApi.getPolicingWaring(url);
    if (resPolice != null) {
      _warningDataCache['policing'] = resPolice.data['result']['rows'];
      createMarkOnMap('policing', _warningDataCache['policing']);
    }
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
      await mapController.clearMarkers(_warningMarkerCache['type']);
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
          double.parse(e['longLatTemp'][0]) >= -180 &&
          double.parse(e['longLatTemp'][0]) <= 180) {
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
                  style: TextStyle(fontSize: 12.0, color: Colors.red),
                )
              ]),
              onTap: () => print('marker click'),
            )));
        return option;
      }
    }
  }

  //点击预警图层操作
  handleLayersClick(type) async {
    //预警信息图层最多打开一个图层
    _warningLayers[type]['isActive'] = !_warningLayers[type]['isActive'];
    //是否显示marker
    if (_warningLayers[type]['isActive']) {
      //先清空另一个图层
      String otherLayer = type == 'meteo' ? 'policing' : 'meteo';
      //判断另一图层 是否是打开状态 ，如果则隐藏
      if (_warningLayers[otherLayer]['isActive']) {
        _warningLayers[otherLayer]['isActive'] = false;
        await mapController.clearMarkers(_warningMarkerCache[otherLayer]);
        _warningMarkerCache[otherLayer].length = 0;
      }
      //地图打点
      var markers = await mapController.addMarkers(_warningLayerCache[type]);
      _warningMarkerCache[type] = markers;
    } else {
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
            await createWarningOptionMarker(marker, info, '确认有效', 0.02, 0.02);
        option2 =
            await createWarningOptionMarker(marker, info, '确认无效', 0.02, -0.02);
      } else if (info[3] == '1') {
        //创建marker
        option1 = await createWarningOptionMarker(
            marker, info, '处置日志', 0.001, -0.001);
        option2 =
            await createWarningOptionMarker(marker, info, '处置结束', 0.001, 0.001);
      }
    }
    //若是警情则展示处置按钮
    else if (info[2] == 'policing') {
      //创建marker
      option1 =
          await createWarningOptionMarker(marker, info, '处置', 0.001, -0.001);
      option2 =
          await createWarningOptionMarker(marker, info, '取消', 0.001, 0.001);
    }
    //缓存marker 并打到地图
    markerToMap(type, option1, option2);
  }

  //操作marker点击处理
  optionMarkerClicked(marker, info) async {
    //先判断是那种预警操作（info[3]）
    if (info[2] == 'meteo') {
      //在判断气象预警当前的状态（未签收和已签收状态，用）
      String text = await marker.title;
      if (info[3] == '0') {
        //确认操作
        showOptionConfirmDialog(text, info, signWarning);
      } else if (info[3] == '1') {
        //判断操作类型
        if (text == '处置日志') {
          //确认有效对应的操作
          meteoWarningDealLog(info, signWarning);
        } else {
          //确认无效对应的操作
          unSignWaning(info, signWarning);
        }
      }
    } else if (info[2] == 'policing') {
      String text = await marker.text;
      //判断操作类型
      if (text == '处置') {
        //确认有效对应的操作
        meteoWarningDealLog(info, signWarning);
      } else {
        //确认无效对应的操作
        cancelDealWaning(info, signWarning);
      }
    }
  }

  //创建预警处理marker(param:预警marker信息，info,按钮展示信息)
  createWarningOptionMarker(marker, info, text, top, left) async {
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
                style: TextStyle(fontSize: 12.0, color: Colors.white),
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
            var child = Container(
              child: Column(
                children: [
                  Container(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Text('$text?', style: TextStyle(fontSize: 16.0))),
                  Container(
                    height: 35.0,
                    padding: EdgeInsets.only(top: 0.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Colors.black12, width: 1.0)),
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
                            onTap: () => signWarning(info, context, text))
                      ],
                    ),
                  )
                ],
              ),
            );

            return Dialog(
                child: child,
                insetPadding:
                    EdgeInsets.symmetric(horizontal: 60.0, vertical: 280.0));
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
    for (int i = _warningMarkerCache[type].length; i > 0; i--) {
      String markerOptionId = await _warningMarkerCache[type][i]['snippet'];
      if (markerOptionId == id) {
        //清除此预警marker
        await mapController.clearMarkers([_warningMarkerCache[type][i]]);
        //清除预警缓存marker;
        _warningMarkerCache[type].remove(_warningMarkerCache[type][i]);
      }
    }

    //marker options
    for (int i = _warningLayerCache[type].length; i > 0; i--) {
      String markerOptionId = await _warningLayerCache[type][i]['snippet'];
      if (markerOptionId == id) {
        _warningLayerCache[type].remove(_warningLayerCache[type][i]);
        if (newDate != null && receiveStatus == '1') {
          var options = createWarningMarkerOption(type, newDate);
          if (options != null) {
            _warningLayerCache[type].add(options);
            //打点
            var markers = await mapController.addMarker(options);
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

  //确认有效操作(签收)
  signWarning(info, context, sign) async {
    String warningId = info[0];
    String type = info[2];
    String receiveStatus = sign == "确认有效" ? '1' : '2';
    var param = {'id': warningId, 'receiveStatus': receiveStatus};
    var res = await RequestApi.signWarning(param);
    if (res != null) {
      // 删除操作marker 地图marker变成可点击状态
      await mapController.clearMarkers(_warningDealingMarkerCache[type]);
      _warningDealingCache[type].length = 0;
      //跟新预警marker
      dealMarker(info[2], warningId, receiveStatus);
      Navigator.of(context).pop();
    }
  }

  //确认无效操作
  unSignWaning(data, context) {
    // Navigator.of(context).pop();
  }

  //预警处置日志
  meteoWarningDealLog(data, context) {}
  //警情处置日志
  policingWarningDealLog(data, context) {}
  //预警处置结束(预警)
  warningDealOver(data, context) {}
  //警情取消处置
  cancelDealWaning(data, context) {}

  Widget _buildAnimation(BuildContext context, Widget child) {
    //退出
    logout() async {
      Navigator.pop(context, '/login');
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
                          )),
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
