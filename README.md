# gt3_flutter_plugin

The official flutter plugin project for geetest. Support Flutter 2.0.
极验3.0 Flutter 官方插件。支持 Flutter 2.0。

[官网/Official](https://www.geetest.com)

## 开始 / Get started

## 安装 / Install

在工程 `pubspec.yaml` 中 `dependencies` 块中添加下列配置 <br>
Follow the steps below to set up dependencies in project pubspec.yaml

**Github 集成** / **Github integration**

```
dependencies:
  gt3_flutter_plugin:
    git:
      url: https://github.com/GeeTeam/gt3_flutter_plugin.git
      ref: master
```

或 / or

**pub 集成** / **pub integration**

```
dependencies:
  gt3_flutter_plugin: 0.1.0
```

## 配置 / Configuration

请在 [官网/Official](https://www.geetest.com) 申请验证 ID（gt）和 Key，并部署配套的后端接口。详细介绍请查阅：[部署说明](https://docs.geetest.com/sensebot/start/)

Create your IDs and keys (GeeTest CAPTCHA V3) on [GeeTest dashboard](https://auth.geetest.com/login), and deploy the corresponding back-end API based on [GeeTest documents](https://docs.geetest.com/captcha/overview/start/). 

## 示例 / Example

### Init

初始化 

```dart
Gt3FlutterPlugin captcha = Gt3FlutterPlugin();
```

或 / or

```dart
Gt3CaptchaConfig config = Gt3CaptchaConfig();
config.language = 'en'; // 设置语言为英文 Set English as the CAPTCHA language
config.cornerRadius = 5.0; // 设置圆角大小为 5.0 Set the corner radius to 5.0
config.timeout = 5.0; // 设置每个请求的超时时间为 5.0 Set the timeout for each request to 5.0 seconds
Gt3FlutterPlugin captcha = Gt3FlutterPlugin(config);
```

### startCaptcha

启动验证

```dart
// 从服务端接口获取验证参数 Get validation parameters from the server API
Gt3RegisterData registerData = Gt3RegisterData(
    gt: ..., // 验证ID，从极验后台创建 Verify ID, created from the geetest dashboard
    challenge: ..., // 从极验服务动态获取 Gain challenges from geetest
    success: ...); // 对极验服务的心跳检测 Check if it is success
captcha.startCaptcha(registerData);
```

### close captcha

关闭验证

```dart
captcha.close();
```

### addEventHandler

添加处理回调

Process callback


```dart
captcha.addEventHandler(
    onShow: (Map<String, dynamic> message) async {
        // TO-DO
        // 验证视图已展示 the captcha view is displayed
        debugPrint("Captcha did show");
    },
    onClose: (Map<String, dynamic> message) async {
        // TO-DO
        // 验证视图已关闭 the captcha view is closed
        debugPrint("Captcha did close");
    },
    onResult: (Map<String, dynamic> message) async {
        debugPrint("Captcha result: " + message.toString());
        String code = message["code"];
        if (code == "1") {
        // TO-DO
        // 发送 message["result"] 中的数据向 B 端的业务服务接口进行查询
        // 对结果进行二次校验 validate the result
        debugPrint("Captcha result code : " + code);
        }
        else {
        // 终端用户完成验证失败，自动重试 If the verification fails, it will be automatically retried. 
        debugPrint("Captcha result code : " + code);
        }
    },
    onError: (Map<String, dynamic> message) async {
        debugPrint("Captcha error: " + message.toString());
        String code = message["code"];

        // 处理验证中返回的错误 Handling errors returned in verification
        if (Platform.isAndroid) { // Android 平台
            if (code == "-2") {
              // Dart 调用异常 Call exception
            } else if (code == "-1") {
              // Gt3RegisterData 参数不合法 Parameter is invalid
            } 
            else if (code == "201") {
              // 网络无法访问 Network inaccessible
            }
            else if (code == "202") {
              // Json 解析错误 Analysis error
            }
            else if (code == "204") {
              // WebView 加载超时，请检查是否混淆极验 SDK   Load timed out
            }
            else if (code == "204_1") {
              // WebView 加载前端页面错误，请查看日志 Error loading front-end page, please check the log
            }
            else if (code == "204_2") {
              // WebView 加载 SSLError
            }
            else if (code == "206") {
              // gettype 接口错误或返回为 null   API error or return null
            }
            else if (code == "207") {
              // getphp 接口错误或返回为 null    API error or return null
            }
            else if (code == "208") {
              // ajax 接口错误或返回为 null      API error or return null
            }
            else {
            // 更多错误码参考开发文档  More error codes refer to the development document
            // https://docs.geetest.com/sensebot/apirefer/errorcode/android
            }
        }

        if (Platform.isIOS) { // iOS 平台
            if (code == "-1009") { 
              // 网络无法访问 Network inaccessible
            }
            else if (code == "-1004") {
              // 无法查找到 HOST  Unable to find HOST
            }
            else if (code == "-1002") {
              // 非法的 URL  Illegal URL
            }
            else if (code == "-1001") { 
              // 网络超时 Network timeout
            }
            else if (code == "-999") {
              // 请求被意外中断, 一般由用户进行取消操作导致 The interrupted request was usually caused by the user cancelling the operation
            }
            else if (code == "-21") {
              // 使用了重复的 challenge   Duplicate challenges are used
              // 检查获取 challenge 是否进行了缓存  Check if the fetch challenge is cached
            }
            else if (code == "-20") {
              // 尝试过多, 重新引导用户触发验证即可 Try too many times, lead the user to request verification again
            }
            else if (code == "-10") {
              // 预判断时被封禁, 不会再进行图形验证 Banned during pre-judgment, and no more image captcha verification
            }
            else if (code == "-2") { 
              // Dart 调用异常 Call exception
            } else if (code == "-1") {
              // Gt3RegisterData 参数不合法  Parameter is invalid
            }
            else {
              // 更多错误码参考开发文档 More error codes refer to the development document
              // https://docs.geetest.com/sensebot/apirefer/errorcode/ios
            }
        }
});
```


