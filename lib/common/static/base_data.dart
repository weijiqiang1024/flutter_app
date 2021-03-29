import 'package:flutter/material.dart';

class BaseData {
  //地图使用到的图片信息
  static List<String> mapDeviceImages = [
    'service', //服务区
    'toll_station', //收费站
    'tunnel', //隧道
    'pivot', //
    'bridge', //桥梁
    'video', //视频
    'screen', //诱导屏
    'speed_limit', //限速牌
    'fog' //雾灯
  ];

  static List<String> getMapDeviceImages() {
    return mapDeviceImages;
  }
}
