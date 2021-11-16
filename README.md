# gt3_flutter_plugin

The official flutter plugin project for geetest. Support Flutter 2.0.
极验3.0 Flutter 官方插件。支持 Flutter 2.0。

[官网/Official](https://www.geetest.com)

## 开始 / Get started

## 安装 / Install

在工程 `pubspec.yaml` 中 `dependencies` 块中添加下列配置

**Github 集成**

```
dependencies:
  gt3_flutter_plugin:
    git:
      url: https://github.com/GeeTeam/gt3_flutter_plugin.git
      ref: master
```

或

**pub 集成**

```
dependencies:
  gt3_flutter_plugin: 0.0.3
```

## 配置 / Configuration

请在 [官网/Official](https://www.geetest.com) 申请验证 ID（gt）和 Key，并部署配套的后端接口。详细介绍请查阅：

[部署说明](https://docs.geetest.com/sensebot/start/)/[Deploy Introduction](https://docs.geetest.com/captcha/overview/start/)

## 示例 / Example

### Init

```dart
Gt3FlutterPlugin captcha = Gt3FlutterPlugin();
```

### startCaptcha

```dart
Gt3RegisterData registerData = Gt3RegisterData(
    gt: ..., // 
    challenge: ..., // 从极验获取
    success: ...); // 
captcha.startCaptcha(registerData);
```

### close

```dart
captcha.close();
```

### addEventHandler

```dart
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

        // 处理验证中返回的错误
        if (Platform.isAndroid) { // Android 平台
            if (code == "-1") {
            // Gt3RegisterData 参数不合法
            }
            else if (code == "201") {
            // 网络无法访问
            }
            else if (code == "202") {
            // Json 解析错误
            }
            else if (code == "204") {
            // WebView 加载超时，请检查是否混淆极验 SDK
            }
            else if (code == "204_1") {
            // WebView 加载前端页面错误，请查看日志
            }
            else if (code == "204_2") {
            // WebView 加载 SSLError
            }
            else if (code == "206") {
            // gettype 接口错误或返回为 null
            }
            else if (code == "207") {
            // getphp 接口错误或返回为 null
            }
            else if (code == "208") {
            // ajax 接口错误或返回为 null
            }
            else {
            // 更多错误码参考开发文档
            // https://docs.geetest.com/sensebot/apirefer/errorcode/android
            }
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
```


