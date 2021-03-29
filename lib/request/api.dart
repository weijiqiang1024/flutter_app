import 'package:dio/dio.dart';
import './request.dart';

class RequestApi {
  // 登录
  static Function get login => (param) => service.request('/login',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", responseType: ResponseType.json));

  //获取用户信息
  static Function get getUserInfo => (url) => service.request(url,
      isShowLoading: true,
      option: new Options(responseType: ResponseType.json));

  //获取设备信息
  static Function get getDeviceInfo => (param) => service.request(
      '/ControlPlatform/service/device/app/device/getDevicesByDeviceTypeAndOrgPrivilegeCode',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post"));

  //获取隧道信息
  static Function get getTunnelInfo => () => service.request(
      '/ControlPlatform/service/visualTopic/bigScreenGisAction/tunnelData',
      isShowLoading: true);

  //获取桥梁信息
  static Function get getBridgeDataInfo => () => service.request(
      '/ControlPlatform/service/visualTopic/bigScreenGisAction/bridgeData',
      isShowLoading: true);

  //获取收费站信息
  static Function get getTollGateInfo => () => service.request(
      '/ControlPlatform/service/visualTopic/bigScreenGisAction/tollGateData',
      isShowLoading: true);

  //获取服务区信息
  static Function get getServiceAreaInfo => () => service.request(
      '/ControlPlatform/service/visualTopic/bigScreenGisAction/serviceAreaData',
      isShowLoading: true);

  //获取交通枢纽信息
  static Function get getPivotInfo => () => service.request(
      '/ControlPlatform/service/visualTopic/bigScreenGisAction/trafficHubData',
      isShowLoading: true);

  //获取预警列表信息
  static Function get getWarningInfo => (param, loading) => service.request(
      '/ControlPlatform/service/trafficWthDetachmentAlarmController/getByCondition',
      params: param,
      isShowLoading: loading,
      option: new Options(method: "post", contentType: 'multipart/form-data'));
  //获取处置日志
  static Function get getDealLog => (param) => service.request(
      '/ControlPlatform/service/trafficWthExecuteLogController/getByCondition',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-data'));

  //删除预警信息
  static Function get deleteWarning => (param) => service.request(
      '/ControlPlatform/service/trafficWthDetachmentAlarmController/deleteById?id=' +
          param['id'],
      isShowLoading: true);

  //获取预警列表信息
  static Function get getReportInfo => (param) => service.request(
      '/ControlPlatform/service/device/app/device/usageInfo/' + param,
      params: param,
      isShowLoading: true);

  //获取登录登出次数
  static Function get getloginCount => (param) => service
      .request('/login/count/' + param, params: param, isShowLoading: true);

  //获取警情
  static Function get getPolicingWaring =>
      (url, loading) => service.request(url, isShowLoading: loading);

  //获取车辆违法
  static Function get getIllegalWaring =>
      (url, loading) => service.request(url, isShowLoading: loading);

  //签收预警
  static Function get signWarning => (param) => service.request(
      '/ControlPlatform/service/trafficWthDetachmentAlarmController/receiveAlarm',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-d5ata'));

  //添加预警日志
  static Function get addWarningLog => (param) => service.request(
      '/ControlPlatform/service/trafficWthExecuteLogController/add',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-data'));

  //结束预警
  static Function get overWarning => (param) => service.request(
      '/ControlPlatform/service/trafficWthDetachmentAlarmController/endAlarm',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-data'));

  //处置措施字典
  static Function get getDealDic => (param) => service.request(
      '/ControlPlatform/service/conCfg/SysCodeAction/selectAllCode?codeType=596',
      params: param,
      isShowLoading: false);

  //添加预警日志
  static Function get addPolicingLog => (param) => service.request(
      '/ControlPlatform/service//trafficMonitor/trafficEvent/progressTrafficEvent1',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-data'));

  //获取雾灯状态
  static Function get getFogStatus =>
      (id) => service.request('/foglight/${id}/status',
          // params: param,
          isShowLoading: true);

  //获取雾灯状态
  static Function get publishFog => (url) => service.request(url,
      // params: param,
      isShowLoading: true,
      // option: new Options(method: "post", contentType: 'multipart/form-data'));
      option: new Options(method: "post", contentType: 'application/json'));

  //添加预警日志图片
  static Function get uploadFile => (param) => service.request(
      '/ControlPlatform/cosUploadServlet',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-data'));

  //添加雾灯控制日志
  static Function get addFogControlLog => (param) => service.request(
      '/ControlPlatform/service/foglightCtrlLogController/add',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post", contentType: 'multipart/form-data'));

  //获取事件图片
  static Function get getEventImage => (param) => service.request(
      '/ControlPlatform/service/trafficMonitor/trafficEventImage/getImagesByEventId',
      params: param,
      isShowLoading: true,
      option: new Options(method: "post"));

  //添加雾灯控制日志
  static Function get getFogControlCount => (url) => service.request(url,
      // params: param,
      isShowLoading: true);
      //获取所有大队警员信息
  static Function get getPoliceAll => () => service.request('/operation/count/all-police',
      // params: param,
      isShowLoading: false);
}
