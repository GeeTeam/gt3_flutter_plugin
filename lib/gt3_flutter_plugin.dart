import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef EventHandler = Function(Map<String, dynamic> event);

class Gt3FlutterPlugin {
  static const String flutterLog = "| Geetest | Flutter | ";
  static const MethodChannel _channel = MethodChannel('gt3_flutter_plugin');

  static String get version {
    return "0.0.8";
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  EventHandler? _onShow;
  EventHandler? _onClose;
  EventHandler? _onResult;
  EventHandler? _onError;

  /// 初始化验证 plugin
  Gt3FlutterPlugin([Gt3CaptchaConfig? config]) {
    if (config == null) {
      config = Gt3CaptchaConfig();
    }

    try {
      _channel.invokeMethod('initWithConfig', config.toMap());
    } catch (e) {
      String desc = flutterLog + e.toString();
      Map<String, String> error = {"code": "-2", "description": desc};
      _onError!(error);
    }
  }

  /// 使用注册参数开启验证
  void startCaptcha(Gt3RegisterData arg) {
    Map<String, dynamic> argument = arg.toMap();
    try {
      _channel.invokeMethod('startCaptcha', argument);
    } catch (e) {
      String desc = flutterLog + e.toString();
      Map<String, String> error = {"code": "-2", "description": desc};
      _onError!(error);
    }
  }

  void configurationChanged(Object object) {
    if (Platform.isAndroid) {
      try {
        _channel.invokeMethod('configurationChanged');
      } catch (e) {
        String desc = flutterLog + e.toString();
        Map<String, String> error = {"code": "-2", "description": desc};
        _onError!(error);
      }
    }
  }

  /// 关闭当前验证界面
  void close() {
    try {
      _channel.invokeMethod('close');
    } catch (e) {
      String desc = flutterLog + e.toString();
      Map<String, String> error = {"code": "-2", "description": desc};
      _onError!(error);
    }
  }

  ///
  /// 注册事件回调
  ///
  void addEventHandler({
    /// 验证视图展示
    EventHandler? onShow,

    /// 用户关闭验证视图
    EventHandler? onClose,

    /// 验证完成，获得验证校验参数
    /// 结构如下:
    /// {"result": {"geetest_challenge": ..., "geetest_seccode": ..., "geetest_validate": ...},
    /// "message": ...,
    /// "code": "1"}
    /// code 为 "1" 则完成验证，需进一步进行二次校验
    /// code 为 "0" 则验证失败，自动进行重试
    EventHandler? onResult,

    /// 错误回调
    /// 结构如下：
    /// {"description": ...},
    /// "code": "-1"}
    /// 需要根据端类型区别处理错误码
    /// Android: https://docs.geetest.com/sensebot/apirefer/errorcode/android
    /// iOS: https://docs.geetest.com/sensebot/apirefer/errorcode/ios
    EventHandler? onError,
  }) {
    print(flutterLog + "addEventHandler:");

    _onShow = onShow;
    _onClose = onClose;
    _onResult = onResult;
    _onError = onError;
    _channel.setMethodCallHandler(_handler);
  }

  /// 原生回调
  Future<dynamic> _handler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "onShow":
        print(flutterLog + "onShow:" + _onShow.toString());
        return _onShow!(methodCall.arguments.cast<String, dynamic>());
      case "onClose":
        print(flutterLog + "onClose:" + _onClose.toString());
        return _onClose!(methodCall.arguments.cast<String, dynamic>());
      case "onResult":
        print(flutterLog + "onResult:" + _onResult.toString());
        return _onResult!(methodCall.arguments.cast<String, dynamic>());
      case "onError":
        print(flutterLog + "onError:" + _onError.toString());
        return _onError!(methodCall.arguments.cast<String, dynamic>());
      default:
        throw UnsupportedError(flutterLog + "Unrecognized Event");
    }
  }
}

class Gt3RegisterData {
  /// 验证 ID
  final String? gt;

  /// 验证 流水号
  final String? challenge;

  /// 是否进入宕机模式
  final bool? success;

  const Gt3RegisterData(
      {@required this.gt, @required this.challenge, @required this.success})
      : assert(gt != null),
        assert(challenge != null),
        assert(success != null);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'gt': gt,
      'challenge': challenge,
      'success': success,
    }..removeWhere((key, value) => value == null);
  }
}

class Gt3CaptchaConfig {
  /// 验证超时时长
  /// 默认 8 秒
  double timeout = 8.0;

  /// 指定验证语言
  /// 默认跟随系统
  /// "ar"(阿拉伯语/Arabic), "de"(德语/German), "en"(英语/English),
  /// "es"(西班牙语/Spanish), "fr"(法语/French), "id"(印尼语/Indonesian),
  /// "ja"(日语/Japanese), "ko"(韩语/Korean), "pt-PT"(葡萄牙语/Portuguese),
  /// "ru"(俄语/Russian), "zh-CN"(简体中文/Chinese Simplified),
  /// "zh-HK"(香港繁体/Chinese Hong Kong), "zh-TW"(台湾繁体/Chinese Taiwan),
  /// "ta"(泰语/Thai), "tr"(土耳其语/Turkish), "vi"(越南语/Vietnamese),
  /// "ta"(泰米尔语/Tamil), "it"(意大利语/Italian), "bn"(孟加拉语/Bengali),
  /// "mr"(马拉地语/Marathi)
  /// 不支持的语言为英文
  String? language;

  /// 验证窗口圆角
  /// 默认 2px
  double? cornerRadius;

  /// 服务集群节点
  /// 0 中国节点，1 中国 IPv6节点
  /// 默认为 0
  int serviceNode = 0;

  /// 点击背景关闭
  /// 默认允许
  bool bgInteraction = true;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'timeout': timeout,
      'language': language,
      'cornerRadius': cornerRadius,
      'serviceNode': serviceNode,
      'bgInteraction': bgInteraction
    }..removeWhere((key, value) => value == null);
  }
}
