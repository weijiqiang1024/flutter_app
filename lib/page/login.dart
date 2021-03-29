// import 'package:flutter/cupertino.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:convert' as convert;
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:police_mobile_sytem/component/hb_toast.dart';

import 'package:police_mobile_sytem/request/api.dart';
import 'package:police_mobile_sytem/socket/web_socket_utility.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';

import 'package:police_mobile_sytem/component/loading_dialog.dart';
import 'package:police_mobile_sytem/component/dialog_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // //输入文本控制
  // TextEditingController _unameController =
  //     new TextEditingController(text: "admin");
  // TextEditingController _pwdController =
  //     new TextEditingController(text: 'ld@12345'.toString());
  TextEditingController _unameController = new TextEditingController(text: "");
  TextEditingController _pwdController = new TextEditingController(text: '');

  //标识记住密码功能
  bool _remaberStatus = true;

  GlobalKey _formKey = new GlobalKey<FormState>(debugLabel: '_loginkey');

  @override
  void initState() {
    super.initState();
    _getLoginMsg();
  }

  // 保存账号密码
  void _saveLoginMsg() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("name", _unameController.text);
    preferences.setString("pwd", _pwdController.text);
  }

  // 读取账号密码，并将值直接赋给账号框和密码框
  void _getLoginMsg() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _unameController.text = preferences.get("name") ?? '';
    _pwdController.text = preferences.get("pwd") ?? '';
  }

  //登录操作
  void login(username, pwd) async {
    var params = {"username": username, "password": generateMd5(pwd)};

    // EasyLoading.show(status: 'loading...');
    Navigator.push(context, DialogRouter(LoadingDialog(true)));
    var response = await RequestApi.login(params);
    var res = response.data;
    // var res = convert.jsonDecode(res1);
    if (res != null) {
      if (res['status'] != null && res['status'] != 200) {
        if (res['status'] == 504) {
          HBToast.showToast('error', '网络响应超时！');
          Navigator.of(context).pop();
          //超时重新请求
          login(username, pwd);
        } else if (res['status'] != null && res['status'] == 401) {
          HBToast.showToast('error', '账号或密码错误！');
          Future.delayed(
              Duration(seconds: 2), () => Navigator.of(context).pop());
        }
        return;
      }

      //记住用户名密码
      if (_remaberStatus) {
        _saveLoginMsg();
      }
      Navigator.of(context).pop();
      // Fluttertoast.showToast(
      //     msg: "登录成功！",
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.CENTER,
      //     timeInSecForIosWeb: 1,
      //     backgroundColor: Colors.black26,
      //     textColor: Colors.white,
      //     fontSize: 16.0);
      HBToast.showToast('success', "登录成功！");

      Navigator.pushReplacementNamed(context, '/home',
          arguments: {'name': 'home'});
      // Navigator.pushReplacementNamed(context, '/home');
      //缓存token信息
      StorageUtil.setStringItem(Constants.StorageMap['token'], res['data']);
      try {
        String url = '/ControlPlatform/service/device/app/userinfo/' + username;
        var responUseInfo = await RequestApi.getUserInfo(url);
        if (responUseInfo != null) {
          var resUserInfo = responUseInfo.data;

          List<String> currentList = new List();
          currentList.add(resUserInfo['userId'] ?? '');
          currentList.add(resUserInfo['policeCode'] ?? '');
          currentList.add(resUserInfo['userName'] ?? '');
          currentList.add(resUserInfo['loginName'] ?? '');
          currentList.add(resUserInfo['orgPrivCode'] ?? '');
          currentList.add(resUserInfo['orgLevel'] ?? '');

          //缓存用户信息
          StorageUtil.setStringListItem(
              Constants.StorageMap['userInfo'], currentList);
        }
      } catch (e) {}

      // Future.delayed(Duration(seconds: 2), () {
      //   EasyLoading.dismiss();
      // });

    }
  }

  // md5 加密
  String generateMd5(String data) {
    var content = new Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    // 这里其实就是 digest.toString()
    return hex.encode(digest.bytes);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final _width = size.width;
    final _height = size.height;
    //输入框底部变化方法
    var inputUnderline = (color) {
      return UnderlineInputBorder(
          borderSide:
              BorderSide(width: 0.8, color: color, style: BorderStyle.solid));
    };
    return Scaffold(
        body: new SingleChildScrollView(
            child: new ConstrainedBox(
                constraints: new BoxConstraints(
                  minHeight: 120.0,
                ),
                child: Container(
                    width: _width,
                    height: _height,
                    decoration: new BoxDecoration(color: Colors.white),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                      alignment: Alignment.center,
                                      children: <Widget>[
                                        Image.asset(
                                          'images/login_head.png',
                                          width: _width,
                                          fit: BoxFit.cover,
                                        ),
                                        Center(
                                            child: Column(children: [
                                          Text('淮北高速交警',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.0,
                                                  letterSpacing: 2.0,
                                                  fontWeight: FontWeight.w500,
                                                  shadows: <Shadow>[
                                                    Shadow(
                                                      offset: Offset(3.0, 3.0),
                                                      blurRadius: 4.0,
                                                      color: Color.fromRGBO(
                                                          0, 0, 0, .6),
                                                    ),
                                                  ])),
                                          Text('移动警务系统',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22.0,
                                                  letterSpacing: 4.0,
                                                  fontWeight: FontWeight.w500,
                                                  shadows: <Shadow>[
                                                    Shadow(
                                                      offset: Offset(3.0, 3.0),
                                                      blurRadius: 4.0,
                                                      color: Color.fromRGBO(
                                                          0, 0, 0, .6),
                                                    ),
                                                  ])),
                                          Text('Mobile Police System',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.0,
                                                  letterSpacing: 2.0,
                                                  fontWeight: FontWeight.w500,
                                                  shadows: <Shadow>[
                                                    Shadow(
                                                      offset: Offset(3.0, 3.0),
                                                      blurRadius: 4.0,
                                                      color: Color.fromRGBO(
                                                          0, 0, 0, .6),
                                                    )
                                                  ]))
                                        ]))
                                      ])
                                ],
                              ),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: Row(children: [
                                          Text('登 录',
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w600)),
                                        ]),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(top: 10.0),
                                          child: Divider(
                                            height: 10.0,
                                            thickness: 0.8,
                                            color: Color(0xffD5D5D5),
                                          )),
                                      Form(
                                        key: _formKey,
                                        autovalidate: true,
                                        child: Column(
                                          children: <Widget>[
                                            TextFormField(
                                                // autofocus: true,
                                                // initialValue: 'admin',
                                                controller: _unameController,
                                                style: TextStyle(height: 2.2),
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.only(top: 3.0),
                                                  enabledBorder: inputUnderline(
                                                      Color(0xffD5D5D5)),
                                                  focusedBorder: inputUnderline(
                                                      Colors.blue),
                                                  errorBorder: inputUnderline(
                                                      Colors.red),
                                                  focusedErrorBorder:
                                                      inputUnderline(
                                                          Colors.red),
                                                  // labelText: '用户名',
                                                  hintText: '请输入账号',
                                                  prefixIcon: Icon(Icons.person,
                                                      color: Colors.blue,
                                                      size: 26.0),
                                                ),
                                                // 校验用户名
                                                validator: (v) {
                                                  return v.trim().length > 0
                                                      ? null
                                                      : "账号不能为空";
                                                }),
                                            TextFormField(
                                                autofocus: false,
                                                // initialValue: '123456',
                                                controller: _pwdController,
                                                style: TextStyle(height: 2.2),
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.only(top: 3.0),
                                                  enabledBorder: inputUnderline(
                                                      Color(0xffD5D5D5)),
                                                  focusedBorder: inputUnderline(
                                                      Colors.blue),
                                                  errorBorder: inputUnderline(
                                                      Colors.red),
                                                  focusedErrorBorder:
                                                      inputUnderline(
                                                          Colors.red),
                                                  // labelText: '密码',
                                                  hintText: '请输入密码',
                                                  prefixIcon: Icon(Icons.lock,
                                                      color: Colors.blue,
                                                      size: 25.0),
                                                ),
                                                obscureText: true,
                                                // 校验用户名
                                                validator: (v) {
                                                  return v.trim().length > 5
                                                      ? null
                                                      : "密码不能少于6位";
                                                }),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  0, 0.0, 0, 0.0),
                                              child: Row(
                                                children: [
                                                  Checkbox(
                                                      value: _remaberStatus,
                                                      activeColor: Colors.blue,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _remaberStatus =
                                                              value;
                                                        });
                                                      }),
                                                  Container(
                                                    child: Text(
                                                      '记住账户',
                                                      style: TextStyle(
                                                          color: _remaberStatus
                                                              ? Colors.blue
                                                              : Colors
                                                                  .grey[700]),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            //登录按钮
                                            Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    2, 30, 2, 0),
                                                width: _width,
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                        offset:
                                                            Offset(0.0, 1.0),
                                                        blurRadius: 4.0,
                                                        color: Color.fromRGBO(
                                                            25, 149, 243, .38))
                                                  ],
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        Color.fromRGBO(
                                                            67, 198, 255, 1),
                                                        Color.fromRGBO(
                                                            67, 142, 255, 1)
                                                      ]),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                                child: RaisedButton(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    child: Text('登 录',
                                                        style: TextStyle(
                                                            fontSize: 20.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w100)),
                                                    color: Colors
                                                        .transparent, // 设为透明色
                                                    elevation: 0, // 正常时阴影隐藏
                                                    highlightElevation:
                                                        0, // 点击时阴影隐藏
                                                    textColor: Colors.white,
                                                    onPressed: () {
                                                      print('************');
                                                      if ((_formKey.currentState
                                                              as FormState)
                                                          .validate()) {
                                                        print(_unameController
                                                            .text);
                                                        print(_pwdController
                                                            .text);
                                                        login(
                                                            _unameController
                                                                .text,
                                                            _pwdController
                                                                .text);
                                                      }
                                                    }))
                                          ],
                                        ),
                                      )
                                    ],
                                  )),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("©2020 安徽蓝盾光电子股份有限公司 V1.0",
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 12.0,
                                  ))
                            ],
                          )
                        ])))));
  }
}
