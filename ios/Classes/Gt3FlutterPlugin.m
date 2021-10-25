#import "Gt3FlutterPlugin.h"
#if __has_include(<gt3_flutter_plugin/gt3_flutter_plugin-Swift.h>)
#import <gt3_flutter_plugin/gt3_flutter_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "gt3_flutter_plugin-Swift.h"
#endif

@interface Gt3FlutterPlugin () <GT3CaptchaManagerDelegate, GT3CaptchaManagerViewDelegate>
@property (nonatomic, strong) GT3CaptchaManager *manager;
@end

@implementation Gt3FlutterPlugin {
    FlutterMethodChannel *_channel;
    FlutterResult  _result;
    FlutterMethodCall  *_call;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
                                      methodChannelWithName:@"gt3_flutter_plugin"
                                      binaryMessenger:[registrar messenger]];
      
    Gt3FlutterPlugin *instance =  [[Gt3FlutterPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];

    [SwiftGt3FlutterPlugin registerWithRegistrar:registrar];
}

- (GT3CaptchaManager *)manager {
    if (!_manager) {
      // 占位即可
      _manager = [[GT3CaptchaManager alloc] initWithAPI1:nil API2:nil timeout:5.0];
      _manager.delegate = self;
      _manager.viewDelegate = self;
      
      [_manager useVisualViewWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
      _manager.maskColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];        
    }
    return _manager;
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
        [_manager registerCaptcha:nil];
    }
    return self;
}

- (void)startCaptcha:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSLog(@"Geetest captcha register params: %@",call.arguments);
    NSString *arg = call.arguments;
    self.flutterResult = flutterResult;
    NSData *jsonData = [arg dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        NSError *error = [[NSError alloc] initWithDomain:@"com.geetest.gt3.flutter" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Register params invalid."}];
        NSDictionary *ret = [self convertToDict:error];
        [_channel invokeMethod:@"onFail" arguments:ret];
        return;
    }

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error];
            
    if (dict) {
        NSString *geetest_id = [dict objectForKey:@"gt"];
        NSString *geetest_challenge = [dict objectForKey:@"challenge"];
        NSNumber *geetest_success = [dict objectForKey:@"success"];
        // 不要在一次验证会话中重复调用
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.manager configureGTest:geetest_id
                            challenge:geetest_challenge
                              success:geetest_success
                            withAPI2:nil];
            [self.manager startGTCaptchaWithAnimated:YES];  
        });
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:@"com.geetest.gt3.flutter" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Register params parse fail."}];
        NSDictionary *ret = [self convertToDict:error];
        [_channel invokeMethod:@"onFail" arguments:ret];
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    if ([@"startCaptcha" isEqualToString:method]) {
        [self startCaptcha:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }

}

#pragma mark GT3CaptchaManagerDelegate

- (BOOL)shouldUseDefaultRegisterAPI:(GT3CaptchaManager *)manager {
    return NO;
}

- (BOOL)shouldUseDefaultSecondaryValidate:(GT3CaptchaManager *)manager {
    return NO;
}

- (void)gtCaptcha:(GT3CaptchaManager *)manager didReceiveCaptchaCode:(NSString *)code result:(NSDictionary *)result message:(NSString *)message {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    [ret setValue:code    forKey:@"code"];
    [ret setValue:result  forKey:@"result"];
    [ret setValue:message forKey:@"message"];
    [_channel invokeMethod:@"onSuccess" arguments:ret];
}

- (void)gtCaptcha:(GT3CaptchaManager *)manager errorHandler:(GT3Error *)error {
    //处理验证中返回的错误
    if (error.code == -999) {
        // 请求被意外中断, 一般由用户进行取消操作导致
    }
    else if (error.code == -10) {
        // 预判断时被封禁, 不会再进行图形验证
    }
    else if (error.code == -20) {
        // 尝试过多
    }
    else {
        // 网络问题或解析失败, 更多错误码参考开发文档
    }

    NSDictionary *ret = [self convertToDict:error];
    [_channel invokeMethod:@"onFail" arguments:ret];
}

#pragma mark GT3CaptchaManagerDelegate

- (NSDictionary *)convertToDict:(NSError *)error {
    NSString *code = [NSString stringWithFormat:@"%lld", error.code];
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    [ret setValue:code            forKey:@"code"];
    [ret setValue:error.userInfo  forKey:@"description"];
    
    return ret;
}

@end
