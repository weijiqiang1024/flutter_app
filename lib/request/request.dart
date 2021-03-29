import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert' as convert;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import './base_url.dart';
import 'package:police_mobile_sytem/uitl/storage_util.dart';
import 'package:police_mobile_sytem/common/static/storage_constants.dart';
import 'package:police_mobile_sytem/main.dart';

// import 'package:police_mobile_sytem/component/loading_dialog.dart';
// import 'package:police_mobile_sytem/component/dialog_route.dart';

class _Service {
  _Service() {
    _initDio();
  }
  Dio _dio = new Dio();
  static String token;
  void setToken(String tk) {
    token = tk;
  }

  void _initDio() {
    // 接口日志
    _dio.interceptors
        .add(LogInterceptor(responseBody: true, requestBody: true));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        // 超时时间
        options.connectTimeout = 25000;
        // 在请求被发送之前做一些事情
        return options;
      },
      onResponse: (Response response) {
        try {
          var res;
          // res = convert.jsonDecode(response.data);
          //后台数据接口返回的数据结构不同意 都要判断 吐了
          if (response.data == null &&
              response.data['status'] &&
              (response.data['status'] != 200 &&
                  response.data['status'] != true)) {
            EasyLoading.showError(
                '请求失败:${response.data['status']} - ${response.data['error']}',
                duration: Duration(seconds: 2));
            response.data = '';
          }
          if (response.data['result'] == null) {
            response.data['result'] = new List();
          }
          response.data = convert.jsonDecode(response.data);

          return response;
        } catch (e) {}
      },
      onError: (DioError error) {
        String msg = '';
        //权限判断
        // if (error.response.statusCode == 401) {
        if (error.error.source == '请求要求用户的身份认证。' ||
            error.response.statusCode == 401) {
          msg = '登录过期，重新登录';
          //清除token缓存
          StorageUtil.getStringItem(Constants.StorageMap['token']) != null ??
              StorageUtil.remove(Constants.StorageMap['token']);
          EasyLoading.showError('请求失败' + msg, duration: Duration(seconds: 2));
          //跳到登录页
          navigatorKey.currentState.pushReplacementNamed('/login');
        } else if (error.response != null && error.response.statusCode == 500) {
          // msg = error.response.data;
        }
        // 当请求失败时做一些预处理
        EasyLoading.showError('请求失败' + msg, duration: Duration(seconds: 2));
        return error;
      },
    ));
  }

  // 真正发请求的地方
  Future request(url,
      {dynamic params,
      Map<String, dynamic> header,
      Options option,
      bool isShowLoading = false}) async {
    Map<String, dynamic> headers = new HashMap();

    // if{

    // }
    //获取token值
    headers['Authorization'] =
        await StorageUtil.getStringItem(Constants.StorageMap['token']) ?? null;

    // headers['Authorization'] =
    //     'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6ImEtYXBwIiwiZXhwIjoxNjAzODQ2MzYwLCJqdGkiOiI2ZjU1ZDE3ZC1hYzI1LTRkOTEtYjYyMS0xYTZkMjU0ZDI3MWIifQ.xn3bqw54evuFCPYjnDcXhij3qf5SvmwZbxKRer5SVdI';

    if (header != null) {
      headers.addAll(header);
    }
    if (option != null) {
      option.headers = headers;
    } else {
      option = new Options(method: "get");
      option.headers = headers;
    }
    // option.receiveDataWhenStatusError = false;
    option.responseType = ResponseType.json;
    option.sendTimeout = 10000;
    option.receiveTimeout = 25000;
    // 是否需要 loading
    if (isShowLoading) {
      // EasyLoading.show(status: 'loading...');
    }
    try {
      // 发送请求获取结果
      // Response _response = await _dio.request('${BaseConfig.baseUrl}$url',
      //     data: convert.jsonEncode(params), options: option);
      Response _response = await _dio.request('${BaseConfig.baseUrl}$url',
          data: params, options: option);
      // isShowLoading == true ??
      //     Future.delayed(Duration(seconds: 0), () {
      //       EasyLoading.dismiss();
      //     });
      // 返回真正结果
      return _response;
    } catch (error) {
      // 异常提示
      if (isShowLoading) EasyLoading.dismiss();
    } finally {
      // 不管结果怎么样 都需要结束Loading
      // isShowLoading == true ??
      //     Future.delayed(Duration(seconds: 2), () {
      //       EasyLoading.dismiss();
      //     });
      if (isShowLoading) EasyLoading.dismiss();
    }
  }
}

final _Service service = new _Service();
