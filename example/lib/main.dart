import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert' as convert;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:gt3_flutter_plugin/gt3_flutter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final Gt3FlutterPlugin captcha = Gt3FlutterPlugin();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await Gt3FlutterPlugin.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    try {
      captcha.addEventHandler(
        onShow: (Map<String, dynamic> message) async {
          // TO-DO
          // 验证视图已展示
          debugPrint("Captcha did show");
        },
        onClose: (Map<String, dynamic> message) async {
          // TO-DO
          // 验证视图已关闭
          debugPrint("Captcha did close");
        },
        onResult: (Map<String, dynamic> message) async {
          debugPrint("Captcha result: " + message.toString());
          String code = message["code"];
          if (code == "1") {
            // TO-DO
            // 发送 message["result"] 中的数据向 B 端的业务服务接口进行查询
            // 对结果进行二次校验
            debugPrint("Captcha result code : " + code);
          }
          else {
            // 终端用户完成验证失败，自动重试
            debugPrint("Captcha result code : " + code);
          }
        },
        onError: (Map<String, dynamic> message) async {
          debugPrint("Captcha error: " + message.toString());
          String code = message["code"];

          // TO-DO
          //处理验证中返回的错误
          if (Platform.isAndroid) { // Android 平台

          }

          if (Platform.isIOS) { // iOS 平台
            if (code == "-1009") {
              // 网络无法访问
            }
            else if (code == "-1004") {
              // 无法查找到 HOST 
            }
            else if (code == "-1002") {
              // 非法的 URL
            }
            else if (code == "-1001") {
              // 网络超时
            }
            else if (code == "-999") {
              // 请求被意外中断, 一般由用户进行取消操作导致
            }
            else if (code == "-21") {
              // 使用了重复的 challenge
              // 检查获取 challenge 是否进行了缓存
            }
            else if (code == "-20") {
              // 尝试过多, 重新引导用户触发验证即可
            }
            else if (code == "-10") {
              // 预判断时被封禁, 不会再进行图形验证
            }
            else if (code == "-1") {
              // Gt3RegisterData 参数不合法
            }
            else {
              // 更多错误码参考开发文档
              // https://docs.geetest.com/sensebot/apirefer/errorcode/ios
            }
          }
          
        });
    }
    catch (e) {
      debugPrint("Event handler exception " + e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // 开始
  void startCaptcha() async {
    debugPrint("Start captcha. Current version: " + _platformVersion);
    // 添加时间戳，避免缓存
      // 如果 challenge 缓存，重复使用，会收到 -21 等错误
      String url = "https://www.geetest.com/demo/gt/register-click?t=" + DateTime.now().toString();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
        Gt3RegisterData registerData = Gt3RegisterData(
          gt: jsonResponse["gt"],
          challenge: jsonResponse["challenge"],
          success: jsonResponse["success"] == 1);
        captcha.startCaptcha(registerData);
      }
  }

  // 关闭
  void close() {
    captcha.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered))
                          return Colors.blue.withOpacity(0.04);
                        if (states.contains(MaterialState.focused) ||
                            states.contains(MaterialState.pressed))
                          return Colors.blue.withOpacity(0.12);
                        return null; // Defer to the widget's default.
                      },
                    ),
                  ),
                  onPressed: startCaptcha,
                  child: Text('点击验证')
                ),
        ),
      ),
    );
  }
}