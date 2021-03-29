import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:police_mobile_sytem/request/api.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';

import 'package:police_mobile_sytem/component/loading_dialog.dart';
import 'package:police_mobile_sytem/component/dialog_route.dart';

class Reporting extends StatefulWidget {
  Reporting({Key key}) : super(key: key);

  @override
  _ReportingState createState() => _ReportingState();
}

class _ReportingState extends State<Reporting> {
  Map report = new Map();
  List typeList = new List();
  List<String> userList = new List();
  String policeName = '--';
  String policeCode = '--';
  String loginCount = '--';
  //机构级别
  String orgLevel = '';
  //警员列表信息
  // List<Map<String,String>> policeInfoList= new List();

  double _top = 0.0; //距顶部的偏移
  double _left = 0.0; //距左边的偏移

  List dataType = [
    {'index': '0', 'name': '气象预警处置次数', 'image': 'moto_report'},
    {'index': '1', 'name': '警情处置次数', 'image': 'police_report'},
    {'index': '2', 'name': '雾灯控制次数', 'image': 'fog_report'},
    {'index': '3', 'name': '视频预览次数', 'image': 'video_report'},
    {'index': '4', 'name': '诱导屏发布次数', 'image': 'screen_report'},
    {'index': '5', 'name': '移动终端指挥调度次数', 'image': 'mobile_terminal'} //检测
  ];

  List policeInfoList = [];

  @override
  void initState(){
    super.initState();
    getReport();
    getLoginCount();
  }

  //获取周报
  getReport() async {
    Future.delayed(Duration.zero, () {
      Navigator.push(context, DialogRouter(LoadingDialog(true)));
    });
    userList =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    // List userInfo = new List();
    String userId = userList.length > 0 ? userList[0] : '';
    policeName = userList[2];
    policeCode = userList[4];
    String loginName = userList[3];
    orgLevel = userList[5];
    if (userList.length == 0) return;
    //雾灯控制次数
    String url = '/operation/foglight/count/$loginName';
    var fogRes = await RequestApi.getFogControlCount(url);
    var res = await RequestApi.getReportInfo(userId);
    //支队用户可查看大队警员信息
    if(userList[5] == '2'){
      var resPolice = await RequestApi.getPoliceAll();
    if(resPolice != null){
      policeInfoList = resPolice.data;
      // policeInfoList.reversed;
    }
    }
    if (res != null) {
      if (res.data is Map) {
        report['0'] = res.data['handleMeteoWarningCount'];
        report['1'] = res.data['handlePoliceCaseCount'];
        report['2'] = res.data['controlFoglightCount'];
        report['3'] = res.data['videoPreviewCount'];
        report['4'] = res.data['publishLedCount'];
        report['5'] = 0; //检测
      }
      if (fogRes != null && fogRes.data != null) {
        report['2'] = fogRes.data['data'];
      }
      setState(() {
        report;
        orgLevel;
        policeName;
        policeCode;
        policeInfoList;
      });
      Navigator.of(context).pop();
    }
  }

  //雾灯控制次数
  getFogControlCount() {}

  getLoginCount() async {
    userList =
        await StorageUtil.getStringListItem(Constants.StorageMap['userInfo']);
    String loginName = userList[3];
    var res = await RequestApi.getloginCount(loginName);
    if (res != null) {
      loginCount = res.data['data'].toString();
      setState(() {
        loginCount;
      });
    }
  }

  String getCount(n) {
    String count = '0';
    if (report[n] != null) {
      count = report[n].toString();
    }
    return count;
  }

  createListItem() {
    List<Widget> childList = new List();
    if (dataType.length > 0) {
      dataType.map((e) {
        // BorderRadius borderRadius;
        // if (e['index'] == 0) {
        //   borderRadius = BorderRadius.only(
        //       topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0));
        // } else if (e['index'] == 4) {
        //   borderRadius = BorderRadius.only(
        //       bottomLeft: Radius.circular(4.0),
        //       bottomRight: Radius.circular(4.0));
        // } else {
        //   borderRadius = BorderRadius.circular(0);
        // }
        Widget child = Container(
          // padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 16.0), //检测
          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(
              color: Colors.white10,
              // borderRadius: borderRadius,
              // border: (e['index'] == '4'
              border: (e['index'] == '5' //检测
                  ? Border(bottom: BorderSide.none)
                  : Border(
                      bottom: BorderSide(color: Colors.white12, width: 1.0)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Row(
                  children: [
                    Image.asset(
                      'images/${e['image']}.png',
                      width: 44.0,
                      height: 44.0,
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text(e['name'],
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.0)),
                    )
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: [
                    Text(
                      getCount(e['index']),
                      style: TextStyle(
                          color: Color.fromRGBO(254, 173, 18, 1),
                          fontSize: 30.0,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        '次',
                        style:
                            TextStyle(color: Color.fromRGBO(254, 173, 18, 1)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
        childList.add(child);
      }).toList();
      return Container(
        child: Column(children: childList),
      );
    }
  }

//无数据处理
  Widget NoData = Container(
    child: Text('暂无数据', style: TextStyle(color: Colors.black45)),
  );

  createPoliceItem() {
    Widget policeList = Expanded(
        child: policeInfoList.length > 0
            ? ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                      // height: 100,
                      alignment: Alignment.center,
                      child: createInfoItem(policeInfoList[index]));
                },
                separatorBuilder: (BuildContext context, int index) {
                  // return Divider();
                  return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 3.0));
                },
                itemCount: policeInfoList.length,
              )
            : NoData);

    return policeList;
  }

  infoRecord(url, text) {
    Widget info = Container(
        child: Column(
      children: [
        Container(
          width: 80.0,
          child: Row(
            children: [
              Container(
                  padding: EdgeInsets.only(right: 6.0),
                  child: Image.asset(url, width: 30.0, height: 30.0)),
              Container(
                child: Text(text.toString(), style: TextStyle(color: Colors.white70)),
              )
            ],
          ),
        )
      ],
    ));

    return info;
  }

  createInfoItem(policeInfo) {
    Widget listItem = Container(
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(4.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              // color: Colors.white10,
              child: Column(
            children: [
              Image.asset('images/user_report1.png', width: 40.0, height: 40.0),
              Text(policeInfo['policeName'], style: TextStyle(color: Colors.white70,fontWeight: FontWeight.w500)),
              Text(policeInfo['orgName'],
                  style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            ],
          )),
          Container(
            child: Column(
              children: [
                Container(
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          infoRecord('images/login_report.png',
                              policeInfo['loginCount']),
                          infoRecord(
                              'images/fog_report.png', policeInfo['controlFoglightCount']),
                        ])),
                Container(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                      infoRecord(
                          'images/moto_report.png', policeInfo['handleMeteoWarningCount']),
                      infoRecord('images/police_report.png',
                          policeInfo['handlePoliceCaseCount']),
                    ])),
              ],
            ),
          )
        ],
      ),
    );

    return listItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '分析报告',
          style: TextStyle(fontSize: 17.0, letterSpacing: 1.0),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color.fromRGBO(67, 143, 255, .9),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        color: Color.fromRGBO(67, 143, 255, .9),
        child: Column(
          children: [
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Row(
                      children: [
                        Image.asset(
                          'images/user_report.png',
                          width: 60.0,
                          height: 60.0,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Column(
                            children: [
                              Text(policeName,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16.0)),
                              Container(
                                margin: EdgeInsets.only(top: 5.0),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                    color: Colors.white70,
                                    borderRadius: BorderRadius.circular(10.0)),
                                child: Text('警号$policeCode',
                                    style: TextStyle(
                                        color: Colors.blue, fontSize: 12.0)),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(right: 14.0),
                    child: Image.asset(
                      'images/report_image.png',
                      width: 100.0,
                      height: 100.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 15.0),
              child: Column(
                children: [
                  Container(
                      width: MediaQuery.of(context).size.width,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('images/week_left.png',
                              width: 10.0, height: 10.0),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.0),
                            child: Text(
                              '本周使用情况',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18.0,
                                  letterSpacing: 1.0,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Image.asset('images/week_right.png',
                              width: 10.0, height: 10.0),
                        ],
                      )),
                  Container(
                      margin: EdgeInsets.fromLTRB(0, 15.0, 0, 5.0),
                      padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4.0)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                              child: Column(children: [
                            Text(loginCount,
                                style: TextStyle(color: Colors.white70)),
                            Text('登录次数',
                                style: TextStyle(color: Colors.white70))
                          ])),
                          Container(
                              child: Column(children: [
                            Text('--', style: TextStyle(color: Colors.white70)),
                            Text('在线时长',
                                style: TextStyle(color: Colors.white70))
                          ]))
                        ],
                      )),
                      orgLevel=='2'?
                  Container(
                      height: 396.0,
                      // constraints: BoxConstraints(),
                      child: DefaultTabController(
                        length: 2,
                        child: TabBarView(children: [
                          createListItem(),
                          Column(children: [createPoliceItem()])
                        ]),
                      )):Container(
                      height: 396.0,
                      // constraints: BoxConstraints(),
                      child: createListItem()),
                  // createListItem()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
