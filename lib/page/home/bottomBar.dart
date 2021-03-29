import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// import 'package:charts_flutter/flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'package:intl/intl.dart';
import 'package:flutter/src/painting/text_style.dart' as _text_style;
// import 'package:flutter/src/material/colors.dart' as __color;
// import 'package:flutter/scheduler.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:police_mobile_sytem/page/warning/index.dart';
import 'package:police_mobile_sytem/page/report/index.dart';
import 'package:police_mobile_sytem/request/api.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';

import 'package:police_mobile_sytem/component/loading_dialog.dart';
import 'package:police_mobile_sytem/component/dialog_route.dart';

import 'package:police_mobile_sytem/component/jhPickerTool.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:police_mobile_sytem/page/dvice_control/video_play.dart';

import 'package:shared_preferences/shared_preferences.dart';

GlobalKey<_MenuStaggedAnimationSate> childBottomKey =
    GlobalKey(debugLabel: '_menuStaggedAnimation');

class MenuStaggedAnimation extends StatefulWidget {
  //控制地图
  final AmapController mapController;
  //动画控制参数
  final AnimationController controller;
  //点击图层按钮对应的动画参数
  final AnimationController animationControllerBottomPanel;

  final Animation<double> bezier; //透明度渐变
  final Animation<EdgeInsets> drift; //位移变化

  final Animation<double> bezierLayer; // 点击图层菜单按钮透明度的变化
  final Animation<EdgeInsets> driftLayer; //位移变化
  final Animation<double> devicePanelHeight; //位移变化

  final AnimationController videoPanelAnimationController;
  final Animation<double> videoBezier; //透明度渐变
  final Animation<EdgeInsets> vidoeDrift; //位移变化
  final Animation<double> videoBezierClick; // 点击图层菜单按钮透明度的变化
  final Animation<EdgeInsets> videoDriftClick; //位移变化

  //地图图层数据
  final Map<String, List> layersData;

  MenuStaggedAnimation(
      {Key key,
      this.controller,
      this.mapController,
      this.animationControllerBottomPanel,
      this.videoPanelAnimationController,
      this.layersData})
      : bezier = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        )),
        bezierLayer = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        )),
        drift = EdgeInsetsTween(
          begin: const EdgeInsets.only(bottom: 0.0),
          end: const EdgeInsets.only(bottom: 100.0),
        ).animate(
          CurvedAnimation(
            parent: controller,
            // curve: Interval(0.375, 0.5, curve: Curves.ease),
            curve: Curves.easeInOut,
          ),
        ),
        driftLayer = EdgeInsetsTween(
          begin: const EdgeInsets.only(bottom: 100.0),
          end: const EdgeInsets.only(bottom: 50.0),
        ).animate(
          CurvedAnimation(
            parent: controller,
            // curve: Interval(0, 1, curve: Curves.ease),
            curve: Curves.easeInOut,
          ),
        ),
        devicePanelHeight = Tween<double>(
          begin: 0.0,
          end: 540.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        )),
        //视频面板动画
        videoBezier = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: videoPanelAnimationController,
          curve: Curves.easeInOut,
        )),
        videoBezierClick = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: videoPanelAnimationController,
          curve: Curves.easeInOut,
        )),
        vidoeDrift = EdgeInsetsTween(
          begin: const EdgeInsets.only(bottom: 0.0),
          end: const EdgeInsets.only(bottom: 100.0),
        ).animate(
          CurvedAnimation(
            parent: videoPanelAnimationController,
            // curve: Interval(0.375, 0.5, curve: Curves.ease),
            curve: Curves.easeInOut,
          ),
        ),
        videoDriftClick = EdgeInsetsTween(
          begin: const EdgeInsets.only(bottom: 100.0),
          end: const EdgeInsets.only(bottom: 0.0),
        ).animate(
          CurvedAnimation(
            parent: videoPanelAnimationController,
            // curve: Interval(0, 1, curve: Curves.ease),
            curve: Curves.easeInOut,
          ),
        ),
        super(key: key);

  @override
  _MenuStaggedAnimationSate createState() => _MenuStaggedAnimationSate();
}

class _MenuStaggedAnimationSate extends State<MenuStaggedAnimation>
    with TickerProviderStateMixin {
  //控制地图
  AmapController mapController;
  //动画控制参数
  AnimationController controller;
  //
  AnimationController _animationControllerBottomPanel;
  AnimationController _videoPanelAnimationController;

  //图层面板显示状态
  bool _panelStatus;

  //video信息面板
  bool _videoPanelStatus;

  //视频信息
  Map _videoInfo = new Map();

  Map<String, List> _layersData = new Map();
  //图层mark缓存信息
  var _deviceLayerCache = {};
  var _hasdeviceLayerCache = {};

  var _mapLayers = {
    'service': {
      'id': 0,
      'name': '服务区',
      'layerName': 'service',
      'layerType': 'map_info',
      'isActive': false
    },
    'toll_station': {
      'id': 1,
      'name': '收费站',
      'layerName': 'toll_station',
      'layerType': 'map_info',
      'isActive': false
    },
    'bridge': {
      'id': 2,
      'name': '桥梁',
      'layerName': 'bridge',
      'layerType': 'map_info',
      'isActive': false
    },
    'tunnel': {
      'id': 3,
      'name': '隧道',
      'layerName': 'tunnel',
      'layerType': 'map_info',
      'isActive': false
    },
    'pivot': {
      'id': 4,
      'name': '枢纽',
      'layerName': 'pivot',
      'layerType': 'map_info',
      'isActive': false
    },
    'video': {
      'id': 5,
      'name': '视频',
      'layerName': 'video',
      'layerType': 'device',
      'code': '03',
      'isActive': false
    },
    'screen': {
      'id': 6,
      'name': '诱导屏',
      'layerName': 'screen',
      'layerType': 'device',
      'code': '06',
      'isActive': false
    },
    'speed_limit': {
      'id': 7,
      'name': '限速牌',
      'layerName': 'speed_limit',
      'layerType': 'device',
      'code': '07',
      'isActive': false
    },
    'fog': {
      'id': 8,
      'name': '雾灯',
      'layerName': 'fog',
      'layerType': 'device',
      'code': '24',
      'isActive': false
    },
  };

  //输入文本控制
  //亮度
  bool _useStatus = false;
  //尾迹长度
  TextEditingController _tailLengthController = new TextEditingController();
  //亮度
  TextEditingController _brightnessController = new TextEditingController();
  //运行模式
  TextEditingController _runModelController = new TextEditingController();
  //闪烁频率
  TextEditingController _flashModelController = new TextEditingController();
  //控制方式
  TextEditingController _controlModelController = new TextEditingController();
  //固定控制开启时间
  TextEditingController _controlOpenTimeController =
      new TextEditingController();
  //固定控制关闭时间
  TextEditingController _controlCloseTimeController =
      new TextEditingController();

  int runModelIndex;
  int flashModelIndex;
  int controlModelIndex;
  int openTimeIndex;
  int closeTimeIndex;
  String runModelName = '';
  String flashModelName = '';
  String controlModelName = '';
  String openTimeName = '';
  String closeTimeName = '';

  var runModelList = ['道路轮廓强化模式', '行车诱导模式', '行车警示模式', '雾霾模式', '事故提醒'];
  var flashModelList = ['30', '60', '90', '常亮'];
  var controlModelList = ['星历控制', '固定时间控制', '阈值控制', '后台控制'];
  var timeModelList = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24'
  ];

  //缓存视频预览信息
  List<String> videoViewHistoryCode = [];
  List<String> videoViewHistoryName = [];

  GlobalKey _fogcontrollerkey =
      new GlobalKey<FormState>(debugLabel: '_fogcontrollerkey');

  @override
  void initState() {
    super.initState();
    mapController = widget.mapController;
    controller = widget.controller;
    _animationControllerBottomPanel = widget.animationControllerBottomPanel;
    _videoPanelAnimationController = widget.videoPanelAnimationController;
    // _layersData = widget.layersData;
    _panelStatus = false;
    //
    _videoPanelStatus = false;
    //获取视频浏览记录缓存
    getVideoViewHistory();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    //销毁动画
    // _animationControllerBottomPanel.dispose();
  }

  getVideoViewHistory() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    //获取历史视频code
    videoViewHistoryCode =
        preferences.getStringList('_videoViewHistoryCode') ?? [];
    //获取历史视频名称
    videoViewHistoryName =
        preferences.getStringList('_videoViewHistoryName') ?? [];
  }

  //获取面板状态供父组件调用
  getPanelStatus() {
    return _panelStatus;
  }

  showLayerPanel() {
    setState(() {
      _panelStatus = !_panelStatus;
    });
    // _playAnimation(_panelStatus);
  }

  //预警消息列表
  showWarningMessage(page) {
    // Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
    //   return page == 'warning' ? Warning() : Reporting();
    // }));

    // EasyLoading.dismiss();

    Navigator.of(context)
        .pushNamed(page == 'warning' ? '/warning' : '/reporting');
  }

  Future<void> _playAnimation(status) async {
    print("22222");
    try {
      if (status) {
        await _animationControllerBottomPanel.forward().orCancel; //开始
      } else {
        await _animationControllerBottomPanel.reverse().orCancel; //反向
      }
    } on TickerCanceled {}
  }

  Future<void> _playVideoAnimation(status) async {
    print("22222");
    try {
      if (status) {
        await _videoPanelAnimationController.forward().orCancel; //开始
      } else {
        await _videoPanelAnimationController.reverse().orCancel; //反向
      }
    } on TickerCanceled {}
  }

  //处理地图图层点击事件
  handleLayersClick(type) async {
    if (type == '') return;
    //判断图层类型，调用请求方法
    if (['video', 'screen', 'speed_limit', 'fog'].contains(type)) {
      //设备类
      getDeviceInfo(type);
    } else {
      //基础设施类
      getRoadBaseInfo(type);
    }
  }

  //点击地图设备marker时响应方法
  onDeviceMarkerClick(marker, info) {
    var type = info[2];
    //先判断点击是预警marker还是操作marker
    switch (type) {
      //雾灯处置
      case 'fog':
        fogDeviceMarker(marker, info);
        break;
      case 'video':
        _videoMarkerClick(marker, info);
        break;
      default:
    }
  }

  //雾灯控制
  fogDeviceMarker(marker, info) async {
    String deviceSysNbr = info[0];
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    //先获取雾灯当前状态
    var res = await RequestApi.getFogStatus(deviceSysNbr);
    Navigator.of(context).pop();
    if (res != null) {
      _useStatus = res.data['state'] == 1 ? true : false;
      _brightnessController.text = (res.data['brightness']).toString();
      _tailLengthController.text = (res.data['wakeLength']).toString();
      _runModelController.text = runModelList[res.data['runMode'] - 1];
      _flashModelController.text = flashModelList[res.data['flashRate'] - 1];
      _controlModelController.text = controlModelList[res.data['ctrlMode'] - 1];
      _controlOpenTimeController.text = res.data['ft_s'].toString();
      _controlCloseTimeController.text = res.data['ft_c'].toString();
      //初始化状态
      setState(() {
        _useStatus;
        _tailLengthController;
        _brightnessController;
        _runModelController;
        _flashModelController;
        _controlModelController;
        runModelIndex = res.data['runMode'];
        flashModelIndex = res.data['flashRate'];
        controlModelIndex = res.data['ctrlMode'];
        openTimeIndex = res.data['ft_s'];
        closeTimeIndex = res.data['ft_c'];
      });
    }
    //控制信息
    fogControlDialog('雾灯控制', info, publishFogController);
  }

  //点击视频图标播放视频
  _videoMarkerClick(marker, info) {
    //动画
    if (!_videoPanelStatus) {
      _videoPanelStatus = true;
      // _playVideoAnimation(_videoPanelStatus);
    }
    _videoInfo['videoName'] = info[3];
    setState(() {
      _videoPanelStatus;
      _videoInfo;
    });
    // _videoPlay();
  }

  //吾等额控制发布
  /**
   * deviceSysCode 设备code
   * type 控制类型
   * param 具体参数info
   */
  publishFogController(info, type, param) async {
    String deviceCode = info[0];
    //管控平台deviceId
    String deviceId = info[4];
    List<String> orgCodeList =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    if (type == 'state') {
      param = param == true ? '1' : '2';
    }
    String url = '/foglight/$deviceCode/$type/$param';
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    //发布
    var res = await RequestApi.publishFog(url);
    if (type == 'ctrlmode' && param == 2) {
      String timeUrl =
          '/foglight/${deviceCode}/ctrltime/${openTimeIndex}/${closeTimeIndex}';
      var res1 = await RequestApi.publishFog(timeUrl);
    }

    DateTime now = DateTime.now();
    var formatterTime = DateFormat('yyyy-MM-dd HH:mm:ss');
    //添加发布日志
    var logParam = {
      'deviceId': deviceId,
      'username': orgCodeList[2],
      'content': addFogLog(info, type, param),
      'invokeDatetime': formatterTime.format(now),
    };

    FormData logFormData = new FormData.fromMap(logParam);

    var logRes = await RequestApi.addFogControlLog(logFormData);

    Navigator.of(context).pop();
    if (res != null) {
      if (res.data['success'])
        Fluttertoast.showToast(
            msg: "发布成功！",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black26,
            textColor: Colors.white,
            fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: "发布失败！",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black26,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  //雾灯控制成功后，添加日志
  addFogLog(info, type, param) {
    if (type == null) return;
    //发布内容
    String publishContent = '';
    switch (type) {
      //开关
      case 'state':
        publishContent = '雾灯状态：' + (param == "1" ? '开' : '关');
        break;
      //尾迹长度
      case 'wakelength':
        publishContent = '尾迹长度：' + param;
        break;
      //亮度
      case 'brightness':
        publishContent = '亮度：' + param;
        break;
      //运行模式
      case 'runmode':
        publishContent = '运行模式：' + _runModelController.text;
        break;
      //闪烁频率
      case 'flashrate':
        publishContent = '闪烁频率：' + flashModelList[param];
        break;
      //控制方式
      case 'ctrlmode':
        publishContent = '控制方式：' + controlModelList[param];
        break;
      default:
    }

    return publishContent;
  }

  //雾灯控制弹框
  Future<void> fogControlDialog(String text, info, callbak) async {
    if (info[0] == null) return;
    var inputUnderline = (color) {
      return UnderlineInputBorder(
          borderSide:
              BorderSide(width: 0.8, color: color, style: BorderStyle.solid));
    };
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, _state) {
              var mediaQueryData = MediaQueryData.fromWindow(ui.window);
              String devcieName = info[3] != '' ? info[3] : text;
              return AnimatedContainer(
                color: Colors.transparent,
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.fromLTRB(
                    20.0, 0, 20.0, mediaQueryData.viewInsets.bottom),
                child: Material(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(devcieName,
                                    style: _text_style.TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600)),
                                GestureDetector(
                                    child: Container(
                                      child: Image.asset(
                                        'images/close.png',
                                        width: 20.0,
                                        height: 20.0,
                                      ),
                                    ),
                                    onTap: () => Navigator.of(context).pop())
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 30.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(children: [
                                    Container(
                                        padding: EdgeInsets.only(left: 28.0),
                                        child: Text('开关：',
                                            style: _text_style.TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400))),
                                    Container(
                                      width: 100.0,
                                      child: Switch(
                                        value: this._useStatus,
                                        activeColor: Colors.blue,
                                        onChanged: (value) {
                                          _state(() {
                                            this._useStatus = value;
                                          });
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 100.0),
                                          child: Image.asset(
                                            'images/publish1.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () => publishFogController(
                                            info, 'state', this._useStatus))
                                  ]),
                                  Row(children: [
                                    Container(
                                        child: Text('尾迹长度：',
                                            style: _text_style.TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400))),
                                    Container(
                                        width: 150.0,
                                        height: 30.0,
                                        // child: Expanded(
                                        //     flex: 1,
                                        child: TextFormField(
                                            controller: _tailLengthController,
                                            style: _text_style.TextStyle(
                                                height: 1.2,
                                                fontSize: 14.0,
                                                color: Colors.blue),
                                            maxLines: 1,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 15.0),
                                              // border: OutlineInputBorder(
                                              //     borderSide: BorderSide()),
                                              enabledBorder: inputUnderline(
                                                  Colors.black45),
                                              focusedBorder:
                                                  inputUnderline(Colors.blue),
                                              // labelText: '日志描述',
                                            ))),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 50.0),
                                          child: Image.asset(
                                            'images/publish1.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () => publishFogController(
                                            info,
                                            'wakelength',
                                            _tailLengthController.text))
                                  ]),
                                  Row(children: [
                                    Container(
                                        padding: EdgeInsets.only(left: 28.0),
                                        child: Text('亮度：',
                                            style: _text_style.TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400))),
                                    Container(
                                        margin: EdgeInsets.only(top: 10.0),
                                        width: 150.0,
                                        height: 30.0,
                                        // child: Expanded(
                                        //     flex: 1,
                                        child: TextFormField(
                                            controller: _brightnessController,
                                            style: _text_style.TextStyle(
                                                height: 1.2,
                                                fontSize: 14.0,
                                                color: Colors.blue),
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 15.0),
                                              enabledBorder: inputUnderline(
                                                  Colors.black45),
                                              focusedBorder:
                                                  inputUnderline(Colors.blue),
                                              // labelText: '日志描述',
                                            ))),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 50.0),
                                          child: Image.asset(
                                            'images/publish1.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () => publishFogController(
                                            info,
                                            'brightness',
                                            _brightnessController.text))
                                  ]),
                                  Row(children: [
                                    Container(
                                        padding: EdgeInsets.only(left: 0.0),
                                        child: Text('运行模式：',
                                            style: _text_style.TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400))),
                                    Container(
                                        margin: EdgeInsets.only(top: 10.0),
                                        width: 150.0,
                                        height: 30.0,
                                        // child: Expanded(
                                        //     flex: 1,
                                        child: TextFormField(
                                            controller: _runModelController,
                                            readOnly: true,
                                            style: _text_style.TextStyle(
                                                height: 1.2,
                                                fontSize: 14.0,
                                                color: Colors.blue),
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 15.0),
                                              enabledBorder: inputUnderline(
                                                  Colors.black45),
                                              focusedBorder:
                                                  inputUnderline(Colors.blue),
                                              // labelText: '日志描述',
                                            ))),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Image.asset(
                                            'images/select_circle.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () {
                                          JhPickerTool.showStringPicker(context,
                                              data: runModelList,
                                              normalIndex: runModelIndex - 1,
                                              clickCallBack:
                                                  (int index, var str) {
                                            _runModelController.text = str;
                                            _state(() {
                                              _runModelController;
                                              runModelIndex = index + 1;
                                              runModelName = str;
                                            });
                                            // print(index);
                                            // print(str);
                                          });
                                        }),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 20.0),
                                          child: Image.asset(
                                            'images/publish1.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () => publishFogController(
                                            info, 'runmode', runModelIndex))
                                  ]),
                                  Row(children: [
                                    Container(
                                        padding: EdgeInsets.only(left: 0.0),
                                        child: Text('闪烁频率：',
                                            style: _text_style.TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400))),
                                    Container(
                                        margin: EdgeInsets.only(top: 10.0),
                                        width: 150.0,
                                        height: 30.0,
                                        // child: Expanded(
                                        //     flex: 1,
                                        child: TextFormField(
                                            controller: _flashModelController,
                                            readOnly: true,
                                            style: _text_style.TextStyle(
                                                height: 1.2,
                                                fontSize: 14.0,
                                                color: Colors.blue),
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 15.0),
                                              enabledBorder: inputUnderline(
                                                  Colors.black45),
                                              focusedBorder:
                                                  inputUnderline(Colors.blue),
                                              // labelText: '日志描述',
                                            ))),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Image.asset(
                                            'images/select_circle.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () {
                                          JhPickerTool.showStringPicker(context,
                                              data: flashModelList,
                                              normalIndex: flashModelIndex - 1,
                                              clickCallBack:
                                                  (int index, var str) {
                                            _flashModelController.text = str;
                                            _state(() {
                                              _tailLengthController;
                                              flashModelIndex = index + 1;
                                              flashModelName = str;
                                            });
                                            // print(index);
                                            // print(str);
                                          });
                                        }),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 20.0),
                                          child: Image.asset(
                                            'images/publish1.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () => publishFogController(
                                            info, 'flashrate', flashModelIndex))
                                  ]),
                                  Row(children: [
                                    Container(
                                        padding: EdgeInsets.only(left: 0.0),
                                        child: Text('控制方式：',
                                            style: _text_style.TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w400))),
                                    Container(
                                        margin: EdgeInsets.only(top: 10.0),
                                        width: 150.0,
                                        height: 30.0,
                                        // child: Expanded(
                                        //     flex: 1,
                                        child: TextFormField(
                                            controller: _controlModelController,
                                            readOnly: true,
                                            style: _text_style.TextStyle(
                                                height: 1.2,
                                                fontSize: 14.0,
                                                color: Colors.blue),
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 15.0),
                                              enabledBorder: inputUnderline(
                                                  Colors.black45),
                                              focusedBorder:
                                                  inputUnderline(Colors.blue),
                                              // labelText: '日志描述',
                                            ))),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Image.asset(
                                            'images/select_circle.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () {
                                          JhPickerTool.showStringPicker(context,
                                              data: controlModelList,
                                              normalIndex:
                                                  controlModelIndex - 1,
                                              clickCallBack:
                                                  (int index, var str) {
                                            _controlModelController.text = str;
                                            _state(() {
                                              _controlModelController;
                                              controlModelIndex = index + 1;
                                              controlModelName = str;
                                            });
                                          });
                                        }),
                                    GestureDetector(
                                        child: Container(
                                          padding: EdgeInsets.only(left: 20.0),
                                          child: Image.asset(
                                            'images/publish1.png',
                                            width: 26.0,
                                            height: 26.0,
                                          ),
                                        ),
                                        onTap: () => publishFogController(info,
                                            'ctrlmode', controlModelIndex))
                                  ]),
                                  controlModelIndex == 2
                                      ? Row(children: [
                                          Container(
                                              padding:
                                                  EdgeInsets.only(left: 0.0),
                                              child: Text('开启时段：',
                                                  style: _text_style.TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400))),
                                          Container(
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              width: 150.0,
                                              height: 30.0,
                                              // child: Expanded(
                                              //     flex: 1,
                                              child: TextFormField(
                                                  controller:
                                                      _controlOpenTimeController,
                                                  readOnly: true,
                                                  style: _text_style.TextStyle(
                                                      height: 1.2,
                                                      fontSize: 14.0,
                                                      color: Colors.blue),
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10.0,
                                                            vertical: 15.0),
                                                    enabledBorder:
                                                        inputUnderline(
                                                            Colors.black45),
                                                    focusedBorder:
                                                        inputUnderline(
                                                            Colors.blue),
                                                    // labelText: '日志描述',
                                                  ))),
                                          GestureDetector(
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
                                                child: Image.asset(
                                                  'images/select_circle.png',
                                                  width: 26.0,
                                                  height: 26.0,
                                                ),
                                              ),
                                              onTap: () {
                                                JhPickerTool.showStringPicker(
                                                    context,
                                                    data: timeModelList,
                                                    normalIndex:
                                                        openTimeIndex - 1,
                                                    clickCallBack:
                                                        (int index, var str) {
                                                  _controlOpenTimeController
                                                      .text = str;
                                                  _state(() {
                                                    _controlOpenTimeController;
                                                    openTimeIndex = index + 1;
                                                    openTimeName = str;
                                                  });
                                                });
                                              }),
                                        ])
                                      : Container(),
                                  controlModelIndex == 2
                                      ? Row(children: [
                                          Container(
                                              padding:
                                                  EdgeInsets.only(left: 0.0),
                                              child: Text('关闭时段：',
                                                  style: _text_style.TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w400))),
                                          Container(
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              width: 150.0,
                                              height: 30.0,
                                              // child: Expanded(
                                              //     flex: 1,
                                              child: TextFormField(
                                                  controller:
                                                      _controlCloseTimeController,
                                                  readOnly: true,
                                                  style: _text_style.TextStyle(
                                                      height: 1.2,
                                                      fontSize: 14.0,
                                                      color: Colors.blue),
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10.0,
                                                            vertical: 15.0),
                                                    enabledBorder:
                                                        inputUnderline(
                                                            Colors.black45),
                                                    focusedBorder:
                                                        inputUnderline(
                                                            Colors.blue),
                                                    // labelText: '日志描述',
                                                  ))),
                                          GestureDetector(
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
                                                child: Image.asset(
                                                  'images/select_circle.png',
                                                  width: 26.0,
                                                  height: 26.0,
                                                ),
                                              ),
                                              onTap: () {
                                                JhPickerTool.showStringPicker(
                                                    context,
                                                    data: timeModelList,
                                                    normalIndex:
                                                        closeTimeIndex - 1,
                                                    clickCallBack:
                                                        (int index, var str) {
                                                  _controlCloseTimeController
                                                      .text = str;
                                                  _state(() {
                                                    _controlCloseTimeController;
                                                    closeTimeIndex = index + 1;
                                                    closeTimeName = str;
                                                  });
                                                });
                                              })
                                        ])
                                      : Container()
                                ])),
                      ],
                    )),
                alignment: Alignment.center,
              );
            },
          );
        });
  }

  //视频播放弹框
  // ignore: unused_element
  Future<void> _videoPlay() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return VideoPlayer(videoInfo: _videoInfo);
          // return VideoPlayer();
        });

    //缓存浏览记录
    setVideoViewHistory(_videoInfo);
  }

  //缓存视频浏览记录
  setVideoViewHistory(videoInfo) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    //获取历史视频code
    List<String> _videoViewHistoryCode =
        preferences.getStringList('_videoViewHistoryCode') ?? [];
    //获取历史视频名称
    List<String> _videoViewHistoryName =
        preferences.getStringList('_videoViewHistoryName') ?? [];

    //设置预览视频code为历史预览
    if (_videoViewHistoryCode.length >= 4) {
      _videoViewHistoryCode
        ..removeAt(0)
        ..add('a9ad94044fda411d8878608929b1c2d1');
      _videoViewHistoryName
        ..removeAt(0)
        ..add(videoInfo['videoName']);
    } else {
      _videoViewHistoryCode.add('a9ad94044fda411d8878608929b1c2d1');
      _videoViewHistoryName.add(videoInfo['videoName']);
    }

    preferences.setStringList('_videoViewHistoryCode', _videoViewHistoryCode);
    preferences.setStringList('_videoViewHistoryName', _videoViewHistoryName);
    //设置预览视频视频名称为历史预览
    setState(() {
      videoViewHistoryCode = _videoViewHistoryCode;
      videoViewHistoryName = _videoViewHistoryName;
    });
  }

  //获取设备信息
  getDeviceInfo(type) async {
    if (_mapLayers[type]['isActive']) {
      //如果是隐藏图层 怎不需要请求资源
      createTypeMarkerInfo(type);
      return;
    }
    //设备类型与管控平台对应
    List<String> orgCodeList =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    var params = {
      "deviceType": _mapLayers[type]['code'],
      "orgPrivilegeCode": orgCodeList[4]
    };
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    try {
      var response = await RequestApi.getDeviceInfo(params);
      Navigator.of(context).pop();
      var res = response.data;
      // if(type == 'video' && response.data.lengtj){
      //    res =
      // }

      if (res != null) {
        _layersData[type] = res;
        createTypeMarkerInfo(type);
      }
    } catch (e) {}
  }

  //获取基础设施信息
  getRoadBaseInfo(type) async {
    //判断是显示还是隐藏图层
    if (_mapLayers[type]['isActive']) {
      //如果是隐藏图层 怎不需要请求资源
      createTypeMarkerInfo(type);
      return;
    }
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    var res;
    try {
      switch (type) {
        case 'service':
          res = await RequestApi.getServiceAreaInfo();
          break;
        case 'toll_station':
          res = await RequestApi.getTollGateInfo();
          break;
        case 'bridge':
          res = await RequestApi.getBridgeDataInfo();
          break;
        case 'tunnel':
          res = await RequestApi.getTunnelInfo();
          break;
        case 'pivot':
          res = await RequestApi.getPivotInfo();
          break;
        default:
      }

      Navigator.of(context).pop();

      if (res.data != null) {
        //数据格式转换
        if (res.data.isNotEmpty) {
          _layersData[type] = new List();
          List mapTemp = new List();
          res.data.map((e) {
            Map mapTempItem = {};
            mapTempItem['siteName'] = e[0];
            mapTempItem['siteLongitude'] =
                (_mapLayers[type]['layerName'] == 'pivot') ? e[2] : e[1];
            mapTempItem['siteLatitude'] =
                (_mapLayers[type]['layerName'] == 'pivot') ? e[3] : e[2];
            mapTemp.add(mapTempItem);
          }).toList();
          _layersData[type] = mapTemp;
        } else {
          _layersData[type] = res.data;
        }
      }

      createTypeMarkerInfo(type);
    } catch (e) {
      print(type + '请求失败');
    }
  }

  //生成地图marker
  createTypeMarkerInfo(type) async {
    _mapLayers[type]['isActive'] = !_mapLayers[type]['isActive'];
    //更新图层选中状态
    setState(() {
      _mapLayers = _mapLayers;
    });
    //图层添加markOptions
    if (_deviceLayerCache.containsKey(type) == false) {
      _deviceLayerCache.addAll({type: <MarkerOption>[]});
      _hasdeviceLayerCache.addAll({type: <Marker>[]});
    }

    if (_mapLayers[type]['isActive'] == true) {
      //判断图层是地图信息 还是 设备信息 区分添加点击事件
      if (_layersData[type].isNotEmpty) {
        _layersData[type].map((e) {
          if (e['siteLatitude'] != null && e['siteLongitude'] != null) {
            var option = MarkerOption(
                object: e['deviceSysNbr'] != null
                    ? e['deviceSysNbr'] +
                        '_device' +
                        '_' +
                        type +
                        '_${e["deviceName"]}' +
                        '_${e["deviceId"]}' +
                        '_marker'
                    : 'base_marker',
                latLng: LatLng(double.parse(e['siteLatitude']),
                    double.parse(e['siteLongitude'])),
                widget: _mapLayers[type]['layerType'] == 'device'
                    ? _getMarkerOnMap(type, e)
                    : Container(
                        child: Column(children: [
                        Image.asset(
                          'images/map/${type}.png',
                          width: 24.0,
                          height: 24.0,
                        ),
                        Text(e['siteName'],
                            style: _text_style.TextStyle(
                                fontSize: 12.0,
                                decoration: TextDecoration.none))
                      ])));
            _deviceLayerCache[type].add(option);
          }
        }).toList();
      }
      //地图打点
      // mapController.addMarkers(_deviceLayerCache[type]);
      var markers = await mapController.addMarkers(_deviceLayerCache[type]);
      _hasdeviceLayerCache[type] = markers;
    } else {
      await mapController.clearMarkers(_hasdeviceLayerCache[type]);
      _hasdeviceLayerCache.remove(type);
      _deviceLayerCache.remove(type);
    }
  }

  //视频设备不加name
  Widget _getMarkerOnMap(type, e) {
    Widget marker = type == 'video'
        ? Container(
            child: Column(children: [
            Image.asset(
              'images/map/${type}.png',
              width: 24.0,
              height: 24.0,
            )
          ]))
        : Container(
            child: Column(children: [
            Image.asset(
              'images/map/${type}.png',
              width: 24.0,
              height: 24.0,
            ),
            Text(
              e['deviceName'],
              style: _text_style.TextStyle(
                  fontSize: 12.0, decoration: TextDecoration.none),
            )
          ]));
    return marker;
  }

  Widget _buildAnimation(BuildContext context, Widget child) {
    //图层列表
    getListView(type, number) {
      // debugger();
      List<Widget> child = [];
      _mapLayers.forEach((key, item) {
        if (item['layerType'] == type) {
          child.add(GestureDetector(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 11.0, vertical: 4.0),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 6.0),
                      child: Image.asset(
                        "images/layers/${item['layerName']}${item['isActive'] ? '_active' : ''}.png",
                        // 'images/layers/service.png',
                        width: 40.0,
                        height: 40.0,
                      ),
                    ),
                    Container(
                      child: Text(
                        item['name'],
                        style: _text_style.TextStyle(
                          decoration: TextDecoration.none,
                          color: Color.fromRGBO(88, 116, 255, 1),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                  ],
                )),
            onTap: () => handleLayersClick(key),
          ));
        }
      });
      // debugger();
      return child;
    }

    //视频管理
    getVideoList() {
      return Container(
          padding: EdgeInsets.symmetric(horizontal: 11.0, vertical: 5.0),
          child: Column(
            children: [
              Container(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Container(
                        child: Row(
                          children: [
                            Container(
                              child: Image.asset(
                                "images/vidoe_high.png",
                                // 'images/layers/service.png',
                                width: 40.0,
                                height: 40.0,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 10.0),
                              child: Text(
                                '高空瞭望视频',
                                style: _text_style.TextStyle(
                                  decoration: TextDecoration.none,
                                  color: Colors.black87,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 40.0),
                        child: Row(
                          children: [
                            Container(
                              child: Image.asset(
                                "images/vidoe_service.png",
                                // 'images/layers/service.png',
                                width: 40.0,
                                height: 40.0,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 10.0),
                              child: Text(
                                '服务区视频',
                                style: _text_style.TextStyle(
                                  decoration: TextDecoration.none,
                                  color: Colors.black87,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  )),
              Container(
                  child: Row(
                children: [
                  Container(
                    child: Row(
                      children: [
                        Container(
                          child: Image.asset(
                            "images/video_station.png",
                            // 'images/layers/service.png',
                            width: 40.0,
                            height: 40.0,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Text(
                            '收费站视频',
                            style: _text_style.TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.black87,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 55.0),
                    child: Row(
                      children: [
                        Container(
                          child: Image.asset(
                            "images/video_suniu.png",
                            // 'images/layers/service.png',
                            width: 40.0,
                            height: 40.0,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Text(
                            '枢纽视频',
                            style: _text_style.TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.black87,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )),
              Container(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Row(children: [
                    Container(
                      child: Image.asset(
                        "images/video_love.png",
                        // 'images/layers/service.png',
                        width: 40.0,
                        height: 40.0,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text(
                        '收藏浏览',
                        style: _text_style.TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.black87,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                  ]))
            ],
          ));
    }

    //点击历史预览视频
    handleVideoClick(code, name) {
      var videoInfo = {'videoCode': code, 'videoName': name};
      setState(() {
        _videoInfo = videoInfo;
      });
      _videoPlay();
    }

    //视频最近看过
    videoHistoryViewList() {
      List<Widget> child = [];

      for (var i = videoViewHistoryCode.length - 1; i >= 0; i--) {
        String code = videoViewHistoryCode[i];
        String name = videoViewHistoryName[i];
        Widget temp = GestureDetector(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 11.0, vertical: 4.0),
                child: Column(
                  children: [
                    Container(
                      child: Text(
                        name,
                        style: _text_style.TextStyle(
                          decoration: TextDecoration.none,
                          color: Color.fromRGBO(88, 116, 255, 1),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    )
                  ],
                )),
            onTap: () => handleVideoClick(code, name));
        child.add(temp);
      }
      return child;
    }

    //图层面板
    var devicePanel = Positioned(
        bottom: 0.0,
        child: Container(
          width: MediaQuery.of(context).size.width - 10.0,
          // height: widget.devicePanelHeight.value,
          // height: MediaQuery.of(context).size.width - 10.0,
          padding: EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 100.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
                color: Colors.white, width: 4.0, style: BorderStyle.solid),
            boxShadow: [
              BoxShadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 12.0,
                  color: Color.fromRGBO(0, 0, 0, .20))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 4.0),
                        child: GestureDetector(
                          child: Image.asset(
                            'images/pack_up.png',
                            width: 50.0,
                            height: 4.0,
                          ),
                          onTap: () => showLayerPanel,
                        )),
                    Container(
                      alignment: Alignment.topLeft,
                      padding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 5.0),
                      child: Text('地图信息',
                          style: _text_style.TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w300,
                              decoration: TextDecoration.none)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: getListView('map_info', 5),
                    ),
                  ],
                ),
              ),
              Container(
                // padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.fromLTRB(0, 8.0, 0, 10.0),
                      child: Text('设备信息',
                          style: _text_style.TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w300,
                              decoration: TextDecoration.none)),
                    ),
                    Row(
                      children: getListView('device', 4),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 5.0),
                      child: Text('分类预览',
                          style: _text_style.TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w300,
                              decoration: TextDecoration.none)),
                    ),
                    Container(
                      child: getVideoList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 5.0),
                      child: Text('最近看过',
                          style: _text_style.TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w300,
                              decoration: TextDecoration.none)),
                    ),
                    Container(
                      child: Column(children: videoHistoryViewList()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
    //底部菜单
    var innerComponent = Stack(
      alignment: Alignment.bottomCenter,
      children: [
        _panelStatus ? devicePanel : new Container(),
        Positioned(
            bottom: _panelStatus ? 31.0 : 34.0,
            child: Container(
              width: 74.0,
              height: 74.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(74.0),
                border: Border.all(
                    color: Colors.white, width: 4.0, style: BorderStyle.solid),
                boxShadow: [
                  BoxShadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 12.0,
                      color: Color.fromRGBO(0, 0, 0, .20))
                ],
              ),
            )),
        Positioned(
            bottom: 40.0,
            child: Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.symmetric(
                    horizontal: _panelStatus
                        ? (MediaQuery.of(context).size.width / 6 - 5)
                        : 20.0,
                    vertical: 0.0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 12.0,
                        color: Color.fromRGBO(0, 0, 0, .20))
                  ],
                  borderRadius: _panelStatus
                      ? BorderRadius.circular(10.0)
                      : BorderRadius.circular(40.0),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.0, vertical: 20.0),
                      child: GestureDetector(
                          child: Row(
                            children: [
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.0, vertical: 0),
                                  child: Image.asset(
                                    'images/message.png',
                                    width: 20.0,
                                    height: 20.0,
                                  )),
                              Text('消息',
                                  style: _text_style.TextStyle(
                                      decoration: TextDecoration.none,
                                      color: Color.fromARGB(170, 0, 0, 0),
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w200))
                            ],
                          ),
                          // onTap: showMessagePanel()),
                          onTap: () => showWarningMessage('warning')),
                    ),
                    Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: _panelStatus ? 22.0 : 10.0,
                            vertical: 0),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(67, 143, 255, 1),
                          borderRadius: BorderRadius.circular(40.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 12.0),
                          child: GestureDetector(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'images/layers_active.png',
                                  width: 20.0,
                                  height: 20.0,
                                ),
                                Text('图层',
                                    style: _text_style.TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Colors.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w200))
                              ],
                            ),
                            onTap: () {
                              print('图层');
                            },
                          ),
                        )),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.0, vertical: 20.0),
                      child: GestureDetector(
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.0, vertical: 0),
                              child: Image.asset(
                                'images/report.png',
                                width: 20.0,
                                height: 20.0,
                              ),
                            ),
                            Text('报告',
                                style: _text_style.TextStyle(
                                    decoration: TextDecoration.none,
                                    color: Color.fromARGB(170, 0, 0, 0),
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w200))
                          ],
                        ),
                        onTap: () => showWarningMessage('report'),
                      ),
                    ),
                  ],
                ))),
        Positioned(
            bottom: _panelStatus ? 31.0 : 34.0,
            child: GestureDetector(
              child: Container(
                width: 75.0,
                height: 75.0,
                // color: Colors.white,
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(75.0),
                    border: Border.all(
                        color: Colors.white,
                        width: 7.0,
                        style: BorderStyle.solid)),
              ),
              onTap: showLayerPanel,
            ))
      ],
    );

    //点击视频设备显示视频信息面板
    var videoInfoComponent =
        Stack(alignment: Alignment.bottomCenter, children: [
      Container(
          height: 130.0,
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          // color: Colors.white,
          width: MediaQuery.of(context).size.width - 10.0,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: Colors.white60, width: 1.0, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: [
                BoxShadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 12.0,
                    color: Color.fromRGBO(0, 0, 0, .20))
              ]),
          child: Container(
            padding: EdgeInsets.fromLTRB(5.0, 40.0, 5.0, 10.0),
            child: Column(
              children: [
                Container(
                    width: double.infinity,
                    child: Row(
                      children: [
                        // Image.asset(
                        //   'images/video_report.png',
                        //   width: 40.0,
                        //   height: 40.0,
                        // ),
                        Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(_videoInfo['videoName'] ?? '--',
                                textAlign: TextAlign.center,
                                style: _text_style.TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(67, 143, 255, 1),
                                    decoration: TextDecoration.none)))
                      ],
                    )),
                Container(
                  padding: EdgeInsets.only(top: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      RaisedButton(
                          shape: StadiumBorder(),
                          color: Colors.white,
                          textColor: Color.fromRGBO(67, 143, 255, 1),
                          onPressed: () {
                            setState(() {
                              _videoPanelStatus = false;
                            });
                          },
                          child: Text('← 取消')),
                      RaisedButton(
                          shape: StadiumBorder(),
                          color: Color.fromRGBO(67, 143, 255, 1),
                          textColor: Colors.white,
                          onPressed: () {
                            setState(() {
                              _videoPanelStatus = false;
                            });
                            _videoPlay();
                          },
                          child: Text('预览 →'))
                    ],
                  ),
                )
              ],
            ),
          )),
      Positioned(
        child: Transform(
            transform: Matrix4.translationValues(0, -98, 0),
            child: Container(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 12.0,
                    color: Color.fromRGBO(67, 143, 255, .2))
              ]),
              child: Image.asset(
                'images/video_report.png',
                width: 50.0,
                height: 50.0,
              ),
            )),
      ),
    ]);
    var outerVideoComponent = _videoPanelStatus
        ? Transform(
            transform: Matrix4.translationValues(0, 95, 0),
            child: Container(
              padding: widget.videoDriftClick.value,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                  //透明组件
                  opacity: widget.videoBezierClick.value,
                  // opacity: 1.0,
                  child: videoInfoComponent),
            ))
        : Transform(
            transform: Matrix4.translationValues(0, 95, 0),
            child: Container(
              padding: widget.vidoeDrift.value,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                  //透明组件
                  opacity: widget.videoBezier.value,
                  // opacity: 1.0,
                  child: videoInfoComponent),
            ));
    //底部菜单动画包装
    var outerComponenet = _panelStatus
        ? Transform(
            transform: Matrix4.translationValues(0, 90, 0),
            child: Container(
              padding: widget.driftLayer.value,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                  //透明组件
                  opacity: widget.bezierLayer.value,
                  child: innerComponent),
            ))
        : Transform(
            transform: Matrix4.translationValues(0, 90, 0),
            child: Container(
              padding: widget.drift.value,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                  //透明组件
                  opacity: widget.bezier.value,
                  child: innerComponent),
            ));
    // return outerComponenet;
    return Stack(children: [outerComponenet, outerVideoComponent]);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: _buildAnimation,
      animation: controller,
    );
  }
}
