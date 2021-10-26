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
      
    Gt3FlutterPlugin *instance = [[Gt3FlutterPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];

//    [SwiftGt3FlutterPlugin registerWithRegistrar:registrar];
}

- (NSString *)getPlatformVersion {
    return [GT3CaptchaManager sdkVersion];
}

- (GT3CaptchaManager *)manager {
    if (!_manager) {
      // 占位即可
      _manager = [[GT3CaptchaManager alloc] initWithAPI1:nil API2:nil timeout:5.0];
      _manager.delegate = self;
      _manager.viewDelegate = self;
      
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
    NSDictionary *arg = call.arguments;
            
    if (arg) {
        NSString *geetest_id = [arg objectForKey:@"gt"];
        NSString *geetest_challenge = [arg objectForKey:@"challenge"];
        NSNumber *geetest_success = [arg objectForKey:@"success"] ? @(1) : @(0);
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
        NSError *error = [[NSError alloc] initWithDomain:@"com.geetest.gt3.flutter" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Register params parse invalid."}];
        NSDictionary *ret = [self convertToDict:error];
        [_channel invokeMethod:@"onError" arguments:ret];
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    if ([@"startCaptcha" isEqualToString:method]) {
        [self startCaptcha:call result:result];
    }
    else if ([@"getPlatformVersion" isEqualToString:method]) {
        result([GT3CaptchaManager sdkVersion]);
    } else {
        result(FlutterMethodNotImplemented);
    }

}

#pragma mark GT3CaptchaManagerDelegate

- (void)gtCaptchaUserDidCloseGTView:(GT3CaptchaManager *)manager {
    [_channel invokeMethod:@"onClose" arguments:@{@"close" : @"1"}];
}

- (BOOL)shouldUseDefaultRegisterAPI:(GT3CaptchaManager *)manager {
    return NO;
}

- (BOOL)shouldUseDefaultSecondaryValidate:(GT3CaptchaManager *)manager {
    return NO;
}

- (void)gtCaptcha:(GT3CaptchaManager *)manager didReceiveCaptchaCode:(NSString *)code result:(NSDictionary *)result message:(NSString *)message {
    NSLog(@"Geetest captcha code: %@ result: %@ message: %@", code, result, message);
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    [ret setValue:code    forKey:@"code"];
    [ret setValue:result  forKey:@"result"];
    [ret setValue:message forKey:@"message"];
    [_channel invokeMethod:@"onResult" arguments:ret];
}

- (void)gtCaptcha:(GT3CaptchaManager *)manager errorHandler:(GT3Error *)error {
    // 处理验证中返回的错误
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
    [_channel invokeMethod:@"onError" arguments:ret];
}

- (void)gtCaptcha:(nonnull GT3CaptchaManager *)manager didReceiveSecondaryCaptchaData:(nullable NSData *)data response:(nullable NSURLResponse *)response error:(nullable GT3Error *)error decisionHandler:(nonnull void (^)(GT3SecondaryCaptchaPolicy))decisionHandler {
    // We don't use this method
}


#pragma mark GT3CaptchaManagerViewDelegate

- (void)gtCaptchaWillShowGTView:(GT3CaptchaManager *)manager {
    [_channel invokeMethod:@"onShow" arguments:@{@"show" : @"1"}];
}

#pragma mark Utils

- (NSDictionary *)convertToDict:(NSError *)error {
    NSString *code = [NSString stringWithFormat:@"%ld", error.code];
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    [ret setValue:code            forKey:@"code"];
    [ret setValue:error.userInfo.description  forKey:@"description"];
    
    return ret;
}

@end
