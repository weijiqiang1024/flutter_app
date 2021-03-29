import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iscflutterplugin/isc_http.dart';
import 'package:iscflutterplugin/isc_player.dart';
import 'package:iscflutterplugin/iscflutterplugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoPlayer extends StatefulWidget {
  final Map videoInfo;

  VideoPlayer({Key key, this.videoInfo}) : super(key: key);
  // VideoPlayer({Key key}) : super(key: key);

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  Iscflutterplugin _controller;
  String _previewUrl;
  var cameraCode;

  Map _videoInfo;

  bool _collectedStatus = false;

  _VideoPlayerState() {
    //初始化配置
    ArtemisConfig.host = "192.168.10.180";
    ArtemisConfig.appKey = "28146904";
    ArtemisConfig.appSecret = "mdGpnXMedJWwsNQXG4GE";
    cameraCode = 'a9ad94044fda411d8878608929b1c2d1';
  }

  @override
  void initState() {
    super.initState();
    _videoInfo = widget.videoInfo;
  }

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQueryData.fromWindow(ui.window);
    String imageUrl =
        "images/${_collectedStatus == false ? '_collected' : '_collected_active'}.png";

    return AnimatedContainer(
        color: Colors.transparent,
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 452.0),
        child: Material(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //标题
                Container(
                  height: 40.0,
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                      color: Color.fromRGBO(67, 143, 255, 1),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_videoInfo['videoName'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500)),
                      Row(children: [
                        GestureDetector(
                            child: Container(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Image.asset(
                                // "images/collect" +
                                //     "${_collectedStatus ? '' : '_active'}.png",
                                imageUrl,
                                width: 20.0,
                                height: 20.0,
                              ),
                            ),
                            onTap: () => _collectedVideo()),
                        GestureDetector(
                            child: Container(
                              child: Image.asset(
                                'images/close.png',
                                width: 20.0,
                                height: 20.0,
                              ),
                            ),
                            onTap: () => _closeVideoPlayer())
                      ])
                    ],
                  ),
                ),
                //视频控件

                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.black,
                  child: IscPlayerWidget(
                    onCreated: _onCreated,
                  ),
                ),
              ],
            )));
  }

  ///创建成功回调
  void _onCreated(controller) {
    _controller = controller;
    _preview();
  }

  ///停止播放
  void _stop() {
    _controller.stopPlay();
  }

  ///预览
  void _preview() async {
    //获取预览地址
    Map ret = await IscApi.getPreviewURL(
        cameraIndexCode: cameraCode, version: 1, streamType: 0);
    _previewUrl = ret['data']['url'];
    print('预览地址 = $_previewUrl');
    //设置播放器状态回调
    _controller.setStatusCallback((status) {
      print('播放器状态 = ${_controller.getStatusMessage(status)}');
    });
    //开始预览
    _controller.startRealPlay(_previewUrl);
  }

  //关闭视频播放窗口
  void _closeVideoPlayer() {
    _stop();
    Navigator.of(context).pop();
  }

  void _collectedVideo() {
    setState(() {
      _collectedStatus = !_collectedStatus;
    });
  }
}
