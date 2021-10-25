
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef Future<dynamic> EventHandler(Map<String, dynamic> event);

class Gt3FlutterPlugin {
  static const String flutterLog = "| Geetest | Flutter | ";
  static const MethodChannel _channel = MethodChannel('gt3_flutter_plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  EventHandler? _onShow;
  EventHandler? _onResult;
  EventHandler? _onError;

  Gt3FlutterPlugin() {
  }

  Future<dynamic> startCaptcha(Gt3RegisterData arg) async {

    Map<String, dynamic> argument = arg.toMap();
    try {
      return await _channel.invokeMethod('startCatpcha', argument);
    } on PlatformException catch (e) {
      print(flutterLog + 'PlatformException');
      return '-1';
    }
  }

  ///
  /// 注册事件回调
  ///
  void addEventHandler({
    EventHandler? onShow,
    EventHandler? onResult,
    EventHandler? onError,
  }) {
    print(flutterLog + "addEventHandler:");

    _onShow     = onShow;
    _onResult   = onResult;
    _onError    = onError;
    _channel.setMethodCallHandler(_handler);
  }

  /// 原生回调
  Future<dynamic> _handler(MethodCall methodCall) async {
    // print("--------FlutterPluginRecord " + methodCall.method);

    String id = (methodCall.arguments as Map)['id'];
    switch (methodCall.method) {
      case "onShow":
          return _onShow!(methodCall.arguments.cast<String, dynamic>());
      case "onSuccess":
          return _onResult!(methodCall.arguments.cast<String, dynamic>());
      case "onFail":
          return _onError!(methodCall.arguments.cast<String, dynamic>());
      default:
        throw UnsupportedError("Unrecognized Event");
    }
  }
}

class Gt3RegisterData {
  final String? gt;
  final String? challenge;
  final bool? success;

  const Gt3RegisterData({
    @required this.gt,
    @required this.challenge,
    @required this.success
  })
  : assert(gt != null),
    assert(challenge != null),
    assert(success != null);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'gt': gt,
      'challenge': challenge,
      'success': success
      }..removeWhere((key, value) => value == null);
  }
}
