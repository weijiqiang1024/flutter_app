import 'package:flutter/material.dart';

class ImageUitls {
  //预加载图片到缓存(单个)
  static void loadPrecacheImage(String name, context,
      {ImageFormat format = ImageFormat.png}) {
    precacheImage(AssetImage("images/map/${name}.png"), context);
  }

  //预加载图片到缓存(单个)
  static void loadPrecacheImages(List nameList, context,
      {ImageFormat format = ImageFormat.png}) {
    nameList.forEach((item) {
      // print(item);
      precacheImage(AssetImage("images/map/${item}.png"), context);
    });
  }
}

enum ImageFormat { png, jpg, gif, webp }
