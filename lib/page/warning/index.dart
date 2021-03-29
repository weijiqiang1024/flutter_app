import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'dart:ui' as ui;
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';
import 'package:police_mobile_sytem/request/api.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:police_mobile_sytem/component/hb_toast.dart';

import 'package:police_mobile_sytem/component/loading_dialog.dart';
import 'package:police_mobile_sytem/component/dialog_route.dart';

import 'package:police_mobile_sytem/page/warning/meteoChart.dart';
import 'package:police_mobile_sytem/page/warning/policingChart.dart';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http_parser/http_parser.dart';
import 'package:police_mobile_sytem/request/base_url.dart';

import 'package:police_mobile_sytem/component/jhPickerTool.dart';

class Warning extends StatefulWidget {
  Warning({Key key}) : super(key: key);

  @override
  _WarningState createState() => _WarningState();
}

class _WarningState extends State<Warning> {
  //meoto预警列表数据
  List warningList = new List();
  //预警总数
  int warningListNum = 0;
  //预警处置日志
  List warningLogList = new List();
  //消息类型标识(0->气象、1->警情)
  int warningTypeFlag = 0;
  //消息类型标识(0->同比、1->环比)
  int chartTypeFlag = 0;
  //polcing预警列表数据
  List warningPoliceList = new List();
  //预警总数
  int warningPoliceNum = 0;
  //处置措施字典
  List dealDicIndex = new List();
  List dealDicName = new List();
  List dealDic = new List();
  int policingDelIndex;
  String policingDelName = '请选择';
  //预警处置描述
  final TextEditingController _warningLogTextController =
      new TextEditingController();
  //警情处置措施
  final TextEditingController _dealStepTextController =
      new TextEditingController();
  //警情处理日志描述
  final TextEditingController _policingLogController =
      new TextEditingController();

  String TOKEN = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDealDic();
    getWarningList();
    getPolicingWarningList();
  }

  //获取警情处置字典
  getDealDic() async {
    TOKEN =
        await StorageUtil.getStringItem(Constants.StorageMap['token']) ?? '';
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

  //获取预警列表数据
  getWarningList() async {
    // TOKEN =
    //     await StorageUtil.getStringItem(Constants.StorageMap['token']) ?? '';
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    // Navigator.push(context, DialogRouter(LoadingDialog(true)));
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(new Duration(days: 3));
    var formatterStart = DateFormat('yyyy-MM-dd HH:mm:ss');
    var formatterEnd = DateFormat('yyyy-MM-dd 23:59:59');
    // DateTime.now().timeZoneName
    var params = {
      'endFlag': '1',
      'receiveStatus': '0,1',
      'isSelectDevAlarm': '1',
      'startTime': formatterStart.format(startTime),
      'endTime': formatterEnd.format(now)
    };
    // EasyLoading.dismiss();
    // EasyLoading.show(status: 'loading...');
    var data = FormData.fromMap(params);
    var res = await RequestApi.getWarningInfo(data, true);
    Navigator.of(context).pop();
    if (res != null) {
      warningList = res.data['result']['rows'];
      warningListNum = res.data['result']['total'];
      setState(() {
        warningList;
        warningListNum;
      });
    }

    // EasyLoading.dismiss();
  }

  //获取警情列表
  getPolicingWarningList() async {
    // String url = '';
    List userInfo =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    //时间
    DateTime now = DateTime.now();
    var formatterTime = DateFormat('yyyy-MM-dd HH:mm:ss');
    var startTime = formatterTime.format(now.subtract(new Duration(hours: 24)));
    var endTime = formatterTime.format(now);
    //未处理事故警情(eventType:1,3,16   停车、行人、交通事件)
    String url =
        '/ControlPlatform/service/trafficMonitor/trafficEvent/selectTrafficEventInfoHistory?currentOrgPrivilegeCode=' +
            userInfo[4] +
            '&handleState=0&eventTime=' +
            startTime +
            '&endTime=' +
            endTime +
            '&pageNumber=1&pageSize=50';
    var res = await RequestApi.getPolicingWaring(url, true);
    if (res != null) {
      //查询所有 目前只展示 人工录入事件及停车、行人预警
      List temp = res.data['result']['rows'];
      warningPoliceList = new List();
      temp.forEach((element) {
        if (['1', '3', '16'].contains(element['eventType']))
          warningPoliceList.add(element);
      });
      // warningPoliceList = res.data['result']['rows'];
      warningPoliceNum = warningPoliceList.length;
      setState(() {
        warningPoliceList;
        warningPoliceNum;
      });
    }
  }

  deleteInfo(id, context) async {
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    var param = {'id': id};
    var res = await RequestApi.deleteWarning(param);
    Navigator.of(context).pop();
    if (res != null) {
      getWarningList();
      Navigator.of(context).pop();
    }
  }

  //删除信息
  Future<void> deleteWarningDialog(info) async {
    if (info['alarmId'] != null) {
      var child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text('确认删除？', style: TextStyle(fontSize: 16.0))),
          Container(
            height: 35.0,
            padding: EdgeInsets.only(top: 0.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: Colors.black12, width: 1.0)),
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
                  onTap: () => deleteInfo(info['alarmId'], context),
                )
              ],
            ),
          )
        ],
      );
      var mediaQueryData = MediaQueryData.fromWindow(ui.window);
      var chidWidget = AnimatedContainer(
        color: Colors.transparent,
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.fromLTRB(
            50.0, 0, 50.0, mediaQueryData.viewInsets.bottom),
        child: Material(borderRadius: BorderRadius.circular(4.0), child: child),
        alignment: Alignment.center,
      );
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return chidWidget;
          });
    }
  }

  Color getColors(level) {
    Color color = Colors.blue;
    switch (level) {
      case '4':
        break;
      case '3':
        color = Colors.yellow;
        break;
      case '2':
        color = Colors.orange[800];
        break;
      case '1':
        color = Colors.red;
        break;
      default:
    }

    return color;
  }

  //六要素参数显示
  sixParts(part, logo) {
    if (part != null && part != '') {
      return Container(
          margin: EdgeInsets.only(right: 14.0),
          child: Row(
            children: [
              Container(
                  padding: EdgeInsets.fromLTRB(0, 4.0, 4.0, 4.0),
                  child: Image.asset(
                    'images/${logo}.png',
                    width: 20.0,
                    height: 20.0,
                  )),
              Container(padding: EdgeInsets.only(left: 5.0), child: Text(part)),
            ],
          ));
    } else {
      return Container();
    }
  }

  //判断预警类型 （风速、温度、能见度、加水量）
  // selectWarningType(item) {
  //   if(){

  //   }
  //   if ((item['devAlarms'] != null) && (item['devAlarms'].length > 0)) {
  //     for (int i = 0; i < item['devAlarms'].length; i++) {}
  //   }
  // }

  //预警项
  createListItem(item) {
    //能见度值
    String visibility = '';
    String water = '';
    String wind = '';
    String temprature = '';
    if ((item['devAlarms'] != null) && (item['devAlarms'].length > 0)) {
      if (item['devAlarms'][0]['isBadVisibility'] != null &&
          item['devAlarms'][0]['isBadVisibility'] != '0')
        visibility = (item['devAlarms'][0]['visibility']).toString() + '米';
      if (item['devAlarms'][0]['isBadTemperature'] != null &&
          item['devAlarms'][0]['isBadTemperature'] != '0')
        temprature = (item['devAlarms'][0]['temperature']).toString() + '℃';
      if (item['devAlarms'][0]['isBadWindSpeed'] != null &&
          item['devAlarms'][0]['isBadWindSpeed'] != '0')
        wind = (item['devAlarms'][0]['windSpeed']).toString() + 'm/s';
      if (item['devAlarms'][0]['isBadWaterFilm'] != null &&
          item['devAlarms'][0]['isBadWaterFilm'] != '0')
        water = (item['devAlarms'][0]['waterFilmHeight']).toString() + 'mm';

      // water = (item['devAlarms'][0]['waterFilmHeight']).toString() + 'mm';
      // wind = (item['devAlarms'][0]['windSpeed']).toString() + 'mm';
      // temprature = (item['devAlarms'][0]['temperature']).toString() + 'mm';

    }
    Widget ListItem = Container(
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Image.asset(
                        'images/site.png',
                        width: 20.0,
                        height: 20.0,
                      ),
                    ),
                    Text(item['position'] == null ? '--' : item['position'])
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: [
                    GestureDetector(
                        child: Container(
                          width: 50.0,
                          height: 24.0,
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                              color: Color.fromRGBO(67, 143, 255, 1),
                              borderRadius: BorderRadius.circular(20.0)),
                          child: Text(
                            '详情',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        onTap: () => showWarningDetail(item)),
                    GestureDetector(
                      child: Container(
                        width: 50.0,
                        height: 24.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(203, 203, 203, 1),
                            borderRadius: BorderRadius.circular(20.0)),
                        child: Text(
                          '删除',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      onTap: () => deleteWarningDialog(item),
                    ),
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 40.0,
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                sixParts(visibility, 'visibility'),
                sixParts(water, 'water'),
                sixParts(wind, 'wind'),
                sixParts(temprature, 'tempure'),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                  padding: EdgeInsets.fromLTRB(0, 4.0, 10.0, 4.0),
                  child: Image.asset(
                    'images/time.png',
                    width: 20.0,
                    height: 20.0,
                  )),
              Text(item['startDate'] == null ? '--' : item['startDate']),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 10.0),
                        child: Image.asset(
                          'images/org.png',
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Text(item['alarmOrgName'] == null
                          ? '--'
                          : item['alarmOrgName'])
                    ],
                  )),
              signStatus(
                  item['receiveStatus'] == null ? '--' : item['receiveStatus']),
              Container(
                  // padding: EdgeInsets.only(right: 10),
                  child: Row(
                children: [
                  item['endFlag'] == '1'
                      ? GestureDetector(
                          child: Container(
                            width: 50.0,
                            height: 24.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 69, 0, 1),
                                borderRadius: BorderRadius.circular(20.0)),
                            child: Text(
                              '上报',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: () => showReportCountDialog('上报', item),
                        )
                      : GestureDetector(
                          child: Container(
                            width: 50.0,
                            height: 24.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(60, 179, 113, 1),
                                borderRadius: BorderRadius.circular(20.0)),
                            child: Text(
                              '办结',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: () => showReportCountDialog('办结', item),
                        )
                ],
              ))

              // Text(item['receiveStatus'] == null ? '--' : item['receiveStatus'])
            ],
          ),
        ],
      ),
    );
    return ListItem;
  }

  //图片窗口
  Future<void> showBigImage(ele, headersMap) async {
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
                        child: Image.network(
                          ele,
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
                              child: Text('关 闭'),
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            // Container(
                            //     height: 35.0,
                            //     // padding: EdgeInsets.symmetric(horizontal: 40.0),
                            //     child: VerticalDivider(color: Colors.black26)),
                            // GestureDetector(
                            //   child: Text(
                            //     '确认',
                            //     style: TextStyle(color: Colors.blue),
                            //   ),
                            //   // onTap: () => signWarning(info, context, text))
                            //   // onTap: () => callbak(info, context, text)
                            // )
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

  //显示图片信息
  Widget loadImage(item) {
    Map<String, String> headersMap = {'Authorization': TOKEN};
    String imageUrl = item['images'];
    List imageTemp = imageUrl.split(',');
    List comImage = new List<Widget>();
    imageTemp.forEach((ele) {
      List eleTemp = ele.split('/');
      eleTemp[0] = BaseConfig.imageUrlConfig;
      ele = eleTemp.join('/');
      comImage.add(GestureDetector(
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Image.network(
                ele,
                headers: headersMap,
                width: 80.0,
                height: 80.0,
              )),
          onTap: () => showBigImage(ele, headersMap)));
    });

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Row(children: comImage));
  }

  //处置日志项
  createLogListItem(item) {
    Widget ListItem = Container(
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Image.asset(
                        'images/login_user.png',
                        width: 20.0,
                        height: 20.0,
                      ),
                    ),
                    Text(item['createUserName'] == null
                        ? '--'
                        : item['createUserName'])
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Image.asset(
                        'images/time.png',
                        width: 20.0,
                        height: 20.0,
                      ),
                    ),
                    Text(item['createDate'] == null ? '--' : item['createDate'])
                  ],
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 10.0),
                        child: Image.asset(
                          'images/log.png',
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Text(item['remark'] == null ? '--' : item['remark'])
                    ],
                  ))
            ],
          ),
          item['images'] != null ? loadImage(item) : Container()
        ],
      ),
    );
    return ListItem;
  }

  //签收状态
  signStatus(status) {
    String str = '--';
    var color = Colors.black;
    switch (status) {
      case '0':
        str = '未签收';
        color = Color.fromRGBO(67, 143, 255, 1);
        break;
      case '1':
        str = '有效';
        color = Color.fromRGBO(95, 220, 126, 1);
        break;
      case '2':
        str = '无效';
        color = Color.fromRGBO(203, 203, 203, 1);
        break;
      default:
    }
    return Container(
        width: 46.0,
        margin: EdgeInsets.only(left: 60),
        alignment: Alignment.bottomRight,
        child: Text(
          str,
          style: TextStyle(color: color),
        ));
  }

  //签收状态
  eventLevel(status) {
    String str = '--';
    var color = Colors.black;
    switch (status) {
      case '0':
        str = '1级';
        color = Color.fromRGBO(95, 220, 126, 1);
        break;
      case '1':
        str = '2级';
        color = Color.fromRGBO(67, 255, 155, 1);
        break;
      case '2':
        str = '2级';
        color = Color.fromRGBO(67, 143, 255, 1);
        break;
      case '3':
        str = '4级';
        color = Color.fromRGBO(255, 231, 67, 1);
        break;
      case '4':
        str = '5级';
        color = Color.fromRGBO(255, 67, 100, 1);
        break;
      default:
    }
    return Container(
        width: 46.0,
        alignment: Alignment.bottomRight,
        child: Text(
          str,
          style: TextStyle(color: color),
        ));
  }

  //审计添加上报和办结
  //处置日志
  Future<void> showReportCountDialog(String text, info) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, _state) {
            // return child;
            TextEditingController _warningLogTextController =
                new TextEditingController();
            _warningLogTextController.text = '';
            var mediaQueryData = MediaQueryData.fromWindow(ui.window);
            return AnimatedContainer(
              color: Colors.transparent,
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.fromLTRB(
                  20.0, 0, 20.0, mediaQueryData.viewInsets.bottom + 40.0),
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
                      Container(
                          // margin: EdgeInsets.symmetric(
                          //   horizontal: 10.0,
                          // ),
                          padding: EdgeInsets.fromLTRB(40.0, 10.0, 10.0, 10.0),
                          child: Row(children: [
                            Container(
                                child: Text('内容：',
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
                                        ))))
                          ])),
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
                                // if (policingDelIndex != null) {
                                //   _state(() {
                                //     policingDelIndex = null;
                                //     policingDelName = '请选择';
                                //   });
                                // }
                                Navigator.of(context).pop();
                              },
                            ),
                            Container(
                                height: 50.0,
                                // padding: EdgeInsets.symmetric(horizontal: 40.0),
                                child: VerticalDivider(color: Colors.black26)),
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
                                onTap: () {
                                  Fluttertoast.showToast(
                                      msg: "提交成功！",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.black26,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                  Navigator.of(context).pop();
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

  //预警详情
  void showWarningDetail(detail) async {
    var param = {'alarmId': detail['alarmId']};
    var data = FormData.fromMap(param);
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    var res = await RequestApi.getDealLog(data);
    Navigator.of(context).pop();
    if (res != null) {
      warningLogList = res.data['result']['rows'];
      showWarningLogDialog(detail, warningLogList);
    }
  }

  //预案详情模态框
  Future<void> showWarningLogDialog(detail, warningLogList) async {
    int index = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        //设备类日志选中标识
        bool _isDeviceType = true;
        //设备类日志选中标识
        bool _unDeviceType = true;
        //日志列表
        List logList = new List();
        logList = this.warningLogList;

        //无数据处理
        Widget NoData = Container(
          child: Text('暂无数据', style: TextStyle(color: Colors.black45)),
        );

        //预警数据处理
        List getLogList(__isDeviceType, __unDeviceType) {
          List _logList = new List();
          if (!__isDeviceType && !__unDeviceType) {
            //都没选
          } else if (!__isDeviceType && __unDeviceType) {
            //只选了非设备类日志
            this.warningLogList.forEach((logItem) {
              if (logItem['pushFlag'] != '1') {
                _logList.add(logItem);
              }
            });
          } else if (__isDeviceType && !__unDeviceType) {
            //只选了设备类日志
            this.warningLogList.forEach((logItem) {
              if (logItem['pushFlag'] == '1') {
                _logList.add(logItem);
              }
            });
          } else {
            //都选了
            _logList = this.warningLogList;
          }
          return _logList;
        }

        return StatefulBuilder(
          builder: (BuildContext context, state) {
            var child = Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                  child: Column(
                    children: [
                      Container(
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('预警信息',
                                  style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w500)),
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
                        child: Column(children: [
                          Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 2.0),
                              child: Row(children: [
                                Text('预警地点:'),
                                Text(detail['position'] != null
                                    ? '  ' + detail['position']
                                    : '  --'),
                              ])),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 2.0),
                            child: Row(children: [
                              Text('预警级别:'),
                              Text(detail['alarmLevel'] != null
                                  ? '  ' + detail['alarmLevel'] + '级'
                                  : '  --'),
                            ]),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 2.0),
                            child: Row(children: [
                              Text('所在道路:'),
                              Text(detail['roadName'] != null
                                  ? '  ' + detail['roadName']
                                  : '  --'),
                            ]),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 2.0),
                            child: Row(children: [
                              Text('预警时间:'),
                              Text(detail['startDate'] != null
                                  ? '  ' + detail['startDate']
                                  : '  --'),
                            ]),
                          ),
                          Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 2.0),
                              child: Row(children: [
                                Text('        描述:'),
                                Text(detail['remark'] != null
                                    ? '  ' + detail['remark']
                                    : '  --'),
                              ])),
                        ]),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Container(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        alignment: Alignment.topLeft,
                        child: Text('处置日志',
                            style: TextStyle(
                                fontSize: 15.0, fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        child: Row(
                          children: [
                            Container(
                              width: 160.0,
                              child: CheckboxListTile(
                                  title: const Text(
                                    '设备日志',
                                    style: TextStyle(fontSize: 14.0),
                                  ),
                                  value: _isDeviceType,
                                  onChanged: (bool value) {
                                    logList = getLogList(value, _unDeviceType);
                                    state(() {
                                      _isDeviceType = !_isDeviceType;
                                      logList;
                                    });
                                  }),
                            ),
                            Container(
                              width: 170.0,
                              child: CheckboxListTile(
                                  title: const Text('处置日志',
                                      style: TextStyle(fontSize: 14.0)),
                                  value: _unDeviceType,
                                  onChanged: (bool value) {
                                    logList = getLogList(_isDeviceType, value);
                                    state(() {
                                      _unDeviceType = !_unDeviceType;
                                      logList;
                                    });
                                  }),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                    child: logList.length > 0
                        ? ListView.separated(
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                  // height: 100,
                                  alignment: Alignment.center,
                                  child: createLogListItem(logList[index]));
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return Divider();
                            },
                            itemCount: logList.length,
                          )
                        : NoData),
              ],
            );
            //使用AlertDialog会报错
            //return AlertDialog(content: child);
            return Dialog(
                child: child,
                insetPadding:
                    EdgeInsets.symmetric(horizontal: 15.0, vertical: 50.0));
          },
        );
      },
    );
  }

  Widget tabBar = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      child: Text('气象预警', style: TextStyle(color: Colors.black87)),
    ),
    Container(
      child: Text('事件预警', style: TextStyle(color: Colors.black87)),
    ),
  ]);

  //警情item
  createPolicingItem(item) {
    Widget ListItem = Container(
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Image.asset(
                        'images/policing_active.png',
                        width: 20.0,
                        height: 20.0,
                      ),
                    ),
                    Text(item['eventName'] == null ? '--' : item['eventName'])
                  ],
                ),
              ),
              GestureDetector(
                  child: Container(
                    width: 50.0,
                    height: 24.0,
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(right: 0.0),
                    decoration: BoxDecoration(
                        color: Color.fromRGBO(67, 143, 255, 1),
                        borderRadius: BorderRadius.circular(20.0)),
                    child: Text(
                      '处置',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  onTap: () => showDealLogDialog(item)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Image.asset(
                        'images/site.png',
                        width: 20.0,
                        height: 20.0,
                      ),
                    ),
                    Text(item['position'] == null ? '--' : item['position'])
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: [
                    signPoliceStatus(item['handleState'] == null
                        ? '--'
                        : item['handleState'])
                  ],
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                          padding: EdgeInsets.fromLTRB(0, 4.0, 10.0, 4.0),
                          child: Image.asset(
                            'images/time.png',
                            width: 20.0,
                            height: 20.0,
                          )),
                      Text(
                          item['eventTime'] == null ? '--' : item['eventTime']),
                    ],
                  )),
              Container(
                child: Row(
                  children: [
                    eventLevel(
                        item['eventLevel'] == null ? '--' : item['eventLevel'])
                  ],
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 10.0),
                        child: Image.asset(
                          'images/log.png',
                          width: 20.0,
                          height: 20.0,
                        ),
                      ),
                      Text(item['eventDesc'] == null ? '--' : item['eventDesc'])
                    ],
                  )),
              // Container(
              //   child: Row(
              //     children: [
              //       eventLevel(item['eventLevel'] == null
              //           ? '--'
              //           : item['eventLevel'])
              //     ],
              //   ),
              // )
            ],
          ),
        ],
      ),
    );
    return ListItem;
  }

  //获取气象预警或警情信息
  Map getDetaiInfo(type, idName, id) {
    Map detail = new Map();
    // if (_warningDataCache['type']?.length == 0) return detail;
    // _warningDataCache[type]?.forEach((element) {
    //   if (element[idName] == id) detail = element;
    // });

    for (int i = 0; i < warningPoliceList.length; i++) {
      if (warningPoliceList[i][idName] == id) detail = warningPoliceList[i];
    }
    return detail;
  }

  String eventImage = "";

  //获取事件图片信息
  getEventImage(id, _state) async {
    if (id == null || id == '') return;
    try {
      var res = await RequestApi.getEventImage(id);
      print(res);
      //获取图片
      if (res != null &&
          !(res is Future) &&
          res.data != null &&
          res.data['result']?.length > 0) {
        String urlTemp = res.data['result'][0]['imageUrl'];
        String temp = urlTemp.replaceAll('http://', '');
        List eleTemp = temp.split('/');
        eleTemp[0] = BaseConfig.imageUrlConfig;
        temp = eleTemp.join('/');
        eventImage = temp;

        _state(() {
          eventImage;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  //获取气象预警类型
  getMeteoWarningType(info) {
    String text = '--';
    if ((info['devAlarms'] != null) && (info['devAlarms'].length > 0)) {
      if (info['devAlarms'][0]['isBadVisibility'] != null &&
          info['devAlarms'][0]['isBadVisibility'] != '0')
        text = (info['devAlarms'][0]['visibility']).toString() + '米';
      if (info['devAlarms'][0]['isBadTemperature'] != null &&
          info['devAlarms'][0]['isBadTemperature'] != '0')
        text = (info['devAlarms'][0]['temperature']).toString() + '℃';
      if (info['devAlarms'][0]['isBadWindSpeed'] != null &&
          info['devAlarms'][0]['isBadWindSpeed'] != '0')
        text = (info['devAlarms'][0]['windSpeed']).toString() + 'm/s';
      if (info['devAlarms'][0]['isBadWaterFilm'] != null &&
          info['devAlarms'][0]['isBadWaterFilm'] != '0')
        text = (info['devAlarms'][0]['waterFilmHeight']).toString() + 'mm';
    }
    return text;
  }

  //展示预警详情组件
  Widget getWarningDetailComponent(type, info, eventImage) {
    Map<String, String> headersMap = {'Authorization': TOKEN};
    //地点、事件/、时间
    Widget addr = Container(
        padding: EdgeInsets.fromLTRB(10.0, 0, 2.0, 10.0),
        child:
            Row(children: [Container(child: Text('地点：${info["position"]}'))]));
    Widget event = Container(
        padding: EdgeInsets.fromLTRB(10.0, 0, 2.0, 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                child: Text(
              '类型：${type == "policing" ? info["eventName"] : getMeteoWarningType(info)}',
              textAlign: TextAlign.left,
            ))
          ],
        ));
    Widget time = Container(
        padding: EdgeInsets.fromLTRB(10.0, 0, 2.0, 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                child: Text(
                    '时间：${type == "policing" ? info["eventTime"] : (info["startDate"] == null ? "--" : info["startDate"])}'))
          ],
        ));

    return Container(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [event, addr, time],
      ),
      type == "policing"
          ? (eventImage != ''
              ? GestureDetector(
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      child: Image.network(
                        // 'http://112.122.188.212:10109/EveImage.aspx?devicenbr=349923000010030020&snapnbr=20201217155734289&server=34.24.231.194&index=0',
                        eventImage,
                        headers: headersMap,
                        fit: BoxFit.cover,
                        width: 125.0,
                        height: 70.0,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes
                                  : null,
                            ),
                          );
                        },
                      )),
                  onTap: () => showBigImage(eventImage, headersMap))
              : Container(
                  child: Image.asset(
                    'images/image_loading.gif',
                    width: 40.0,
                    height: 40.0,
                  ),
                ))
          : Container()
    ]));
  }

  //警情处置日志
  savePolicingDealLog(info, context) async {
    String type = info[2];
    //判断日志填写是否为空
    if (_warningLogTextController != null &&
        _warningLogTextController.text != null &&
        _warningLogTextController.text != '' &&
        policingDelIndex != null) {
      List<String> uesrInfo =
          await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
      var param = {
        'eventId': info["eventId"],
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
      await getPolicingWarningList();
      Navigator.of(context).pop();
      if (res != null) {
        // 删除操作marker 地图marker变成可点击状态
        HBToast.showToast('success', "处置成功！");
        setState(() {
          policingDelIndex = null;
          policingDelName = '';
        });
        Navigator.of(context).pop();
      } else {
        HBToast.showToast('error', "处置失败！");
      }
    }
  }

  //警情处置
  Future<void> showDealLogDialog(info) async {
    //取消图片地址重复请求问题
    bool reqImageUrlFlag = true;
    if (info['eventId'] != null) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, _state) {
              var mediaQueryData = MediaQueryData.fromWindow(ui.window);
              Map detail = new Map();
              //判断是气象还是警情
              String url = '';
              String _type = 'policing';
              String idName = _type == 'meteo' ? 'alarmId' : 'eventId';
              detail = getDetaiInfo(_type, idName, info['eventId']);
              // Map<String, String> headersMap = {'Authorization': TOKEN};
              if (_type == 'meteo') {
                //获取气象信息
              } else if (_type == 'policing' &&
                  eventImage == "" &&
                  reqImageUrlFlag) {
                //获取警情图片信息
                getEventImage(info['eventId'], _state);
              }
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
                          child: Text('事件预警处置',
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w600)),
                        ),
                        getWarningDetailComponent(_type, detail, eventImage),
                        Divider(
                          height: 1.0,
                          color: Colors.grey[200],
                          thickness: 1.0,
                        ),
                        Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 10.0),
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
                                            highlightColor: Colors.blue[700],
                                            colorBrightness: Brightness.dark,
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
                            ])),
                        Container(
                            padding: EdgeInsets.fromLTRB(40.0, 2.0, 10.0, 10.0),
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
                        // text == "添加日志" ? showAddImage(_state) : Container(),
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
                                  // imagesUrlList.length = 0;
                                  // imagesTransforUrlList.length = 0;
                                  // images.length = 0;
                                  // resultList.length = 0;
                                  _state(() {
                                    policingDelIndex = null;
                                    policingDelName = '请选择';
                                    //图片url
                                    eventImage = "";
                                    reqImageUrlFlag = false;
                                    _warningLogTextController;
                                    // images;
                                    // resultList;
                                    // imagesUrlList;
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
                                    await savePolicingDealLog(info, context);
                                    if (policingDelIndex != null ||
                                        _warningLogTextController.text != '') {
                                      _warningLogTextController.text = '';
                                      //上传图片缓存清空
                                      // imagesUrlList.length = 0;
                                      // imagesTransforUrlList.length = 0;
                                      _state(() {
                                        policingDelIndex = null;
                                        eventImage = "";
                                        reqImageUrlFlag = false;
                                        policingDelName = '请选择';
                                        _warningLogTextController;
                                        // imagesUrlList;
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

  signPoliceStatus(status) {
    String str = '--';
    var color = Colors.black;
    switch (status.toString()) {
      case '0':
        str = '未处置';
        color = Color.fromRGBO(67, 143, 255, 1);
        break;
      case '1':
        str = '处置中';
        color = Colors.orange;
        break;
      case '2':
        str = '已处置';
        color = Color.fromRGBO(203, 203, 203, 1);
        break;
      default:
    }
    return Text(
      str,
      style: TextStyle(color: color),
    );
  }

  //预警类型切换
  changeTabBar(key) {
    setState(() {
      warningTypeFlag = key;
    });
  }

  //图表类型切换
  changeChartTabBar(key) {
    setState(() {
      chartTypeFlag = key;
    });
  }

  Widget getMeteoBar(type) {
    List<Barsales> dataBar0 = [
      new Barsales("2019-12", 1),
      new Barsales("2020-12", 4),
    ];

    List<Barsales> dataBar1 = [
      new Barsales("2020-11", 62),
      new Barsales("2020-12", 4),
    ];

    var seriesBar = [
      charts.Series(
        data: type == 0 ? dataBar0 : dataBar1,
        colorFn: (_, __) => type == 0
            ? charts.MaterialPalette.blue.shadeDefault
            : charts.MaterialPalette.red.shadeDefault,
        domainFn: (Barsales sales, _) => sales.day,
        measureFn: (Barsales sales, _) => sales.sale,
        labelAccessorFn: (Barsales sales, _) => '${sales.sale.toString()}',
        id: "Sales",
      )
    ];
    return charts.BarChart(seriesBar,
        barGroupingType: charts.BarGroupingType.stacked,
        barRendererDecorator: charts.BarLabelDecorator<String>());

    // List<OrdinalSales> dataBar1 = [
    //   new OrdinalSales("11", 1),
    //   new OrdinalSales("12", 2),
    // ];

    // List<OrdinalSales> dataBar2 = [
    //   new OrdinalSales("11", 62),
    //   new OrdinalSales("12", 4),
    // ];

    // var seriesList = [
    //   charts.Series<OrdinalSales, String>(
    //     id: 'Sales',
    //     colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
    //     domainFn: (OrdinalSales sales, _) => sales.year,
    //     measureFn: (OrdinalSales sales, _) => sales.sales,
    //     data: dataBar1,
    //   ),
    //   charts.Series<OrdinalSales, String>(
    //     id: 'Sales',
    //     colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
    //     domainFn: (OrdinalSales sales, _) => sales.year,
    //     measureFn: (OrdinalSales sales, _) => sales.sales,
    //     data: dataBar2,
    //   )
    // ];

    // return charts.BarChart(
    //   seriesList,
    //   animate: true,
    //   // barGroupingType: charts.BarGroupingType.stacked,
    //   // barRendererDecorator: charts.BarLabelDecorator<String>(),
    // );
  }

  Widget getPolicingBar(type) {
    List<Barsales> dataBar0 = [
      new Barsales("2019-12", 15),
      new Barsales("2020-12", 3),
    ];

    List<Barsales> dataBar1 = [
      new Barsales("2020-11", 10),
      new Barsales("2020-12", 3),
    ];

    var seriesBar = [
      charts.Series(
        data: type == 0 ? dataBar0 : dataBar1,
        colorFn: (_, __) => type == 0
            ? charts.MaterialPalette.blue.shadeDefault
            : charts.MaterialPalette.red.shadeDefault,
        domainFn: (Barsales sales, _) => sales.day,
        measureFn: (Barsales sales, _) => sales.sale,
        labelAccessorFn: (Barsales sales, _) => '${sales.sale.toString()}',
        id: "Sales",
      )
    ];
    return charts.BarChart(seriesBar,
        barGroupingType: charts.BarGroupingType.stacked,
        barRendererDecorator: charts.BarLabelDecorator<String>());

    // List<OrdinalSales> dataBar1 = [
    //   new OrdinalSales("11", 0),
    //   new OrdinalSales("12", 0),
    // ];

    // List<OrdinalSales> dataBar2 = [
    //   new OrdinalSales("11", 4),
    //   new OrdinalSales("12", 1),
    // ];

    // var seriesList = [
    //   charts.Series<OrdinalSales, String>(
    //     id: 'Sales',
    //     colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
    //     domainFn: (OrdinalSales sales, _) => sales.year,
    //     measureFn: (OrdinalSales sales, _) => sales.sales,
    //     data: dataBar1,
    //   ),
    //   charts.Series<OrdinalSales, String>(
    //     id: 'Sales',
    //     colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
    //     domainFn: (OrdinalSales sales, _) => sales.year,
    //     measureFn: (OrdinalSales sales, _) => sales.sales,
    //     data: dataBar2,
    //   )
    // ];

    // return charts.BarChart(
    //   seriesList,
    //   animate: true,
    //   // barGroupingType: charts.BarGroupingType.stacked,
    //   // barRendererDecorator: charts.BarLabelDecorator<String>(),
    //   // barRendererDecorator: charts.BarLabelDecorator<String>(),
    // );
  }

  Future<void> showChart(key) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, _state) {
              var mediaQueryData = MediaQueryData.fromWindow(ui.window);
              return AnimatedContainer(
                color: Colors.transparent,
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.fromLTRB(
                    10.0, 0, 10.0, mediaQueryData.viewInsets.bottom),
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
                                Text(key == 0 ? "气象预警同比/环比" : "事件预警同比/环比",
                                    style: TextStyle(
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
                                    onTap: () {
                                      _state(() {
                                        chartTypeFlag = 0;
                                      });
                                      Navigator.of(context).pop();
                                    })
                              ],
                            )),
                        Container(
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                // crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Transform(
                                  transform:
                                      Matrix4.translationValues(0, 5.0, 0),
                                  child: GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(
                                          10.0, 5.0, 10, 10.0),
                                      decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: chartTypeFlag == 0
                                                    ? Colors.blue
                                                    : Colors.white,
                                                width: 2.0)),
                                      ),
                                      child: Text('同比',
                                          style: TextStyle(
                                              color: chartTypeFlag == 0
                                                  ? Colors.blue
                                                  : Colors.black87)),
                                    ),
                                    onTap: () {
                                      _state(() {
                                        chartTypeFlag = 0;
                                      });
                                    },
                                  )),
                              Transform(
                                transform: Matrix4.translationValues(0, 5.0, 0),
                                child: GestureDetector(
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        10.0, 5.0, 10, 10.0),
                                    decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: chartTypeFlag == 1
                                                  ? Colors.blue
                                                  : Colors.white,
                                              width: 2.0)),
                                    ),
                                    child: Text('环比',
                                        style: TextStyle(
                                            color: chartTypeFlag == 1
                                                ? Colors.blue
                                                : Colors.black87)),
                                  ),
                                  onTap: () {
                                    _state(() {
                                      chartTypeFlag = 1;
                                    });
                                  },
                                ),
                              )
                            ])),
                        Container(
                            width: 320.0,
                            height: 250.0,
                            padding: EdgeInsets.fromLTRB(0, 10.0, 0, 20.0),
                            child: key == 0
                                ? getMeteoBar(chartTypeFlag)
                                : getPolicingBar(chartTypeFlag))
                      ],
                    )),
                alignment: Alignment.center,
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
        child: Scaffold(
            appBar: AppBar(
                title: Text(
                  '消息中心',
                  style: TextStyle(
                      fontSize: 17.0,
                      letterSpacing: 1.0,
                      color: Colors.black87),
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.white,
                brightness: Brightness.light,
                iconTheme: IconThemeData(color: Colors.black87)),
            body: Container(
              color: Color.fromRGBO(241, 241, 241, 1),
              padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 0),
              child: Container(
                  color: Colors.white,
                  child: Column(children: [
                    // Divider(thickness: 5.0, color: Color.fromRGBO(241, 241, 241, 1)),
                    Container(
                        // width: MediaQuery.of(context).size.width - 40.0,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            // crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform(
                                  transform:
                                      Matrix4.translationValues(0, 5.0, 0),
                                  child: GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(
                                          10.0, 5.0, 10, 10.0),
                                      decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: warningTypeFlag == 0
                                                    ? Colors.blue
                                                    : Colors.white,
                                                width: 2.0)),
                                      ),
                                      child: Text('气象预警(${warningListNum})',
                                          style: TextStyle(
                                              color: warningTypeFlag == 0
                                                  ? Colors.blue
                                                  : Colors.black87)),
                                    ),
                                    onTap: () => changeTabBar(0),
                                  )),
                              Transform(
                                transform: Matrix4.translationValues(0, 5.0, 0),
                                child: GestureDetector(
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        10.0, 5.0, 10, 10.0),
                                    decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: warningTypeFlag == 1
                                                  ? Colors.blue
                                                  : Colors.white,
                                              width: 2.0)),
                                    ),
                                    child: Text('事件预警(${warningPoliceNum})',
                                        style: TextStyle(
                                            color: warningTypeFlag == 1
                                                ? Colors.blue
                                                : Colors.black87)),
                                  ),
                                  onTap: () => changeTabBar(1),
                                ),
                              )
                            ])),
                    Divider(
                        thickness: 5.0,
                        color: Color.fromRGBO(241, 241, 241, 1)),
                    Container(
                      // margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 0),
                      height: MediaQuery.of(context).size.height - 150.0,
                      child: ListView.separated(
                          itemBuilder: (BuildContext context, int index) {
                            String level = warningTypeFlag == 0
                                ? warningList[index]['alarmLevel']
                                : warningPoliceList[index][''];
                            return Container(
                              // margin: EdgeInsets.symmetric(vertical: 5.0),
                              decoration: BoxDecoration(
                                // borderRadius: BorderRadius.circular(13.0),
                                border: Border(
                                  left: BorderSide(
                                      color: getColors(level),
                                      width: 3.0,
                                      style: BorderStyle.solid),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: warningTypeFlag == 0
                                  ? createListItem(warningList[index])
                                  : createPolicingItem(
                                      warningPoliceList[index]),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(
                              thickness: 5.0,
                              height: 0,
                              color: Color.fromRGBO(241, 241, 241, 1),
                            );
                          },
                          itemCount: this.warningTypeFlag == 0
                              ? this.warningList.length
                              : this.warningPoliceList.length),
                    ),
                  ])),
            ),
            floatingActionButton: new FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () => showChart(warningTypeFlag),
              tooltip: 'Increment',
              child: Image.asset(
                'images/chart.png',
                width: 30.0,
                height: 30.0,
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat));
  }
}

class Barsales {
  String day;
  int sale;
  Barsales(this.day, this.sale);
}

class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}
