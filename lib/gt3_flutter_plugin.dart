
import 'dart:async';

import 'package:flutter/services.dart';

class Gt3FlutterPlugin {
  static const MethodChannel _channel = MethodChannel('gt3_flutter_plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
