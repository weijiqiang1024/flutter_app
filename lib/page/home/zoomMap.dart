import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
import 'package:amap_map_fluttify/amap_map_fluttify.dart';

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
    //地图放大
    zoomScale() {
      print('zoomOut');
      mapController.zoomIn();
    }

    //地图缩小
    reduceScale() {
      mapController.zoomOut();
      print('zoomIn');
    }

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
                                width: 34.0,
                                height: 80.0,
                                margin:
                                    EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      child: Image.asset(
                                        'images/scale_plus.png',
                                        width: 14.0,
                                        height: 14.0,
                                      ),
                                      onTap: zoomScale,
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4.0, vertical: 0.0),
                                        child: Divider(
                                          height: 2.0,
                                          thickness: 0.8,
                                          color: Color(0xffD5D5D5),
                                        )),
                                    GestureDetector(
                                      child: Image.asset(
                                        'images/scale_reduce.png',
                                        width: 14.0,
                                        height: 14.0,
                                      ),
                                      onTap: reduceScale,
                                    )
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
