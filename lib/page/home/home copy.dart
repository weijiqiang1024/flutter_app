// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';

class Home extends StatelessWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
  @override
  _CreateMapScreenState createState() => _CreateMapScreenState();
}

class _CreateMapScreenState extends State<CreateMapScreen>
    with TickerProviderStateMixin {
  //地图控制类
  AmapController _controller;
  //动画控制类
  AnimationController _animationController;
  //地图点击标记(0->初始显示；1->隐藏)
  bool _mapClickStatus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _mapClickStatus = true;
    //显示动画
    _playAnimation(_mapClickStatus);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    //销毁动画
    _animationController.dispose();
  }

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

  //监听地图点击事件
  _onMapClicked(controller) async {
    print("1111");
    print(controller);
    print("1111");
    _mapClickStatus = !_mapClickStatus;
    _playAnimation(_mapClickStatus);
  }

  @override
  Widget build(BuildContext context) {
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
                _controller.showTraffic(true);
              },
              onMapClicked: (controller) async {
                _onMapClicked(controller);
              }),
          //上方操作面板
          StaggedAnimation(
              controller: _animationController.view,
              mapController: _controller),
          // Positioned(
          //     bottom: 100.0,
          //     right: 0.0,
          //     child: Container(
          //       alignment: Alignment.bottomCenter,
          //       margin: EdgeInsets.only(bottom: 40.0),
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.start,
          //         children: [
          //           Container(
          //               alignment: Alignment.topLeft,
          //               width: 36.0,
          //               height: 80.0,
          //               margin: EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
          //               decoration: BoxDecoration(
          //                 boxShadow: [
          //                   BoxShadow(
          //                       offset: Offset(0.0, 1.0),
          //                       blurRadius: 4.0,
          //                       color: Color.fromRGBO(0, 0, 0, .38))
          //                 ],
          //                 borderRadius: BorderRadius.circular(4.0),
          //                 color: Colors.white,
          //               ),
          //               child: Column(
          //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //                 children: [
          //                   Image.asset(
          //                     'images/scale_plus.png',
          //                     width: 16.0,
          //                     height: 16.0,
          //                   ),
          //                   Padding(
          //                       padding: EdgeInsets.symmetric(
          //                           horizontal: 4.0, vertical: 0.0),
          //                       child: Divider(
          //                         height: 2.0,
          //                         thickness: 0.8,
          //                         color: Color(0xffD5D5D5),
          //                       )),
          //                   Image.asset(
          //                     'images/scale_reduce.png',
          //                     width: 16.0,
          //                     height: 16.0,
          //                   ),
          //                 ],
          //               ))
          //         ],
          //       ),
          //     )),
          ZoomStaggedAnimation(
              controller: _animationController.view,
              mapController: _controller),
          Positioned(
              bottom: 36.0,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                      child: Container(
                    width: 70.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      // color: Colors.black,
                      borderRadius: BorderRadius.circular(70.0),
                      border: Border.all(
                          color: Colors.white,
                          width: 4.0,
                          style: BorderStyle.solid),
                      boxShadow: [
                        BoxShadow(
                            offset: Offset(0.0, 1.0),
                            blurRadius: 4.0,
                            color: Color.fromRGBO(0, 0, 0, .38))
                      ],
                    ),
                  ))
                ],
              )),
          Positioned(
              bottom: 40.0,
              child: Container(
                  alignment: Alignment.bottomCenter,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(0.0, 1.0),
                          blurRadius: 4.0,
                          color: Color.fromRGBO(0, 0, 0, .38))
                    ],
                    borderRadius: BorderRadius.circular(40.0),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 20.0),
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
                                    style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Color.fromARGB(170, 0, 0, 0),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w200))
                              ],
                            ),
                            onTap: () => print('消息')),
                      ),
                      Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 0),
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
                                      style: TextStyle(
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
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 20.0),
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
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    color: Color.fromARGB(170, 0, 0, 0),
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w200))
                          ],
                        ),
                      ),
                    ],
                  ))),
          Positioned(
              bottom: 36.0,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    child: Positioned(
                        child: Container(
                      width: 70.0,
                      height: 70.0,
                      decoration: BoxDecoration(
                          // color: Colors.black,
                          borderRadius: BorderRadius.circular(70.0),
                          border: Border.all(
                              color: Colors.white,
                              width: 4.0,
                              style: BorderStyle.solid)),
                    )),
                    onTap: () => print('图层'),
                  )
                ],
              ))
          //下方操作面板
        ]);
  }
}

class StaggedAnimation extends StatelessWidget {
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

  Widget _buildAnimation(BuildContext context, Widget child) {
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
                            offset: Offset(0.0, 1.0),
                            blurRadius: 4.0,
                            color: Color.fromRGBO(0, 0, 0, .38))
                      ],
                      borderRadius: BorderRadius.circular(4.0),
                      color: Colors.white,
                    ),
                    child: Image.asset(
                      'images/logout.png',
                      width: 20.0,
                      height: 20.0,
                    ),
                  ),
                  Container(
                      alignment: Alignment.topRight,
                      width: 36.0,
                      height: 80.0,
                      margin: EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              offset: Offset(0.0, 1.0),
                              blurRadius: 4.0,
                              color: Color.fromRGBO(0, 0, 0, .38))
                        ],
                        borderRadius: BorderRadius.circular(4.0),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset(
                            'images/meteo_active.png',
                            width: 20.0,
                            height: 20.0,
                          ),
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.0, vertical: 0.0),
                              child: Divider(
                                height: 2.0,
                                thickness: 0.8,
                                color: Color(0xffD5D5D5),
                              )),
                          Image.asset(
                            'images/warning_active.png',
                            width: 20.0,
                            height: 20.0,
                          ),
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

class ZoomStaggedAnimation extends StatelessWidget {
  //控制地图
  final AmapController mapController;
  //动画控制参数
  final Animation<double> controller;
  final Animation<double> bezier; //透明度渐变
  final Animation<EdgeInsets> drift; //位移变化

  ZoomStaggedAnimation({Key key, this.controller, this.mapController})
      : bezier = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        )),
        drift = EdgeInsetsTween(
          begin: const EdgeInsets.only(bottom: 0.0),
          end: const EdgeInsets.only(bottom: 140.0),
        ).animate(
          CurvedAnimation(
            parent: controller,
            // curve: Interval(0.375, 0.5, curve: Curves.ease),
            curve: Curves.easeInOut,
          ),
        ),
        super(key: key);

  Widget _buildAnimation(BuildContext context, Widget child) {
    return Transform(
        transform: Matrix4.translationValues(0, 0, 0),
        child: Container(
          padding: drift.value,
          alignment: Alignment.topCenter,
          child: Opacity(
              //透明组件
              opacity: bezier.value,
              child: Stack(
                children: [
                  Positioned(
                      bottom: -40.0,
                      right: 0.0,
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        margin: EdgeInsets.only(bottom: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                                alignment: Alignment.topLeft,
                                width: 36.0,
                                height: 80.0,
                                margin:
                                    EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                        offset: Offset(0.0, 1.0),
                                        blurRadius: 4.0,
                                        color: Color.fromRGBO(0, 0, 0, .38))
                                  ],
                                  borderRadius: BorderRadius.circular(4.0),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Image.asset(
                                      'images/scale_plus.png',
                                      width: 16.0,
                                      height: 16.0,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4.0, vertical: 0.0),
                                        child: Divider(
                                          height: 2.0,
                                          thickness: 0.8,
                                          color: Color(0xffD5D5D5),
                                        )),
                                    Image.asset(
                                      'images/scale_reduce.png',
                                      width: 16.0,
                                      height: 16.0,
                                    ),
                                  ],
                                ))
                          ],
                        ),
                      )),
                ],
              )),
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
