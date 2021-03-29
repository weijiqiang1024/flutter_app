import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HBToast {
  String status;
  String msg;

  HBToast({this.status, this.msg});

  static showToast(status, msg) {
    return Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black26,
        textColor: status == 'success' ? Colors.white : Colors.red,
        fontSize: 16.0);
  }
}
