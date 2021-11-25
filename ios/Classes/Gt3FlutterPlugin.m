#import "Gt3FlutterPlugin.h"

#define UIColorFromRGB(rgbaValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF000000) >> 24))/255.0 green:((float)((rgbValue & 0xFF0000) >> 16))/255.0 blue:((float)((rgbValue & 0xFF00) >> 8))/255.0 alpha:(float)(rgbValue & 0xFF)/255.0]

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

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
    }
    return self;
}

- (void)init:(FlutterMethodCall*)call result:(FlutterResult)flutterResult {
    NSLog(@"Geetest captcha register params: %@",call.arguments);
    NSDictionary *arg = call.arguments;
    NSLog(@"flutter config: %@", arg.description);
    if (arg) {
        NSNumber *timeout = arg[@"timeout"];
        NSString *language = arg[@"language"];
        NSString *bgColorHex = arg[@"bgColor"];
        NSNumber *cornerRadius = arg[@"cornerRadius"];
        NSNumber *serviceNode = arg[@"serviceNode"];
        BOOL bgInteraction = arg[@"bgInteraction"];

        _manager = [[GT3CaptchaManager alloc] initWithAPI1:nil API2:nil timeout:timeout.doubleValue];
        _manager.delegate = self;
        _manager.viewDelegate = self;
        
        if (language) [_manager useLanguageCode:language];
        _manager.maskColor = [self colorFromHexString:bgColorHex] ?: [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        if (cornerRadius) [_manager useGTViewWithCornerRadius:cornerRadius.doubleValue];
        if (serviceNode) [_manager useServiceNode:(GT3CaptchaServiceNode)serviceNode.integerValue];
        [_manager disableBackgroundUserInteraction:!bgInteraction];

        [_manager registerCaptcha:nil];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:@"com.geetest.gt3.flutter" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"GT3Captcha iOS Initial fail. Register params parse invalid."}];
        NSDictionary *ret = [self convertToDict:error];
        [_channel invokeMethod:@"onError" arguments:ret];
    }
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
    if ([@"initWithConfig" isEqualToString:method]) {
        [self init:call result:result];
    }
    else if ([@"startCaptcha" isEqualToString:method]) {
        [self startCaptcha:call result:result];
    }
    else if ([@"getPlatformVersion" isEqualToString:method]) {
        result([GT3CaptchaManager sdkVersion]);
    } else {
        result(FlutterMethodNotImplemented);
    }

}

- (UIColor *)colorFromHexString:(NSString *)hexColorString {
    // 删除字符串中的空格
    NSString *cString = [[hexColorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 10 characters
    if ([cString length] < 6)
    {
        return nil;
    }
    // strip 0X if it appears
    // 如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }
    // 如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
     
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    // r
    NSString *rString = [cString substringWithRange:range];
    // g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    // b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // a
    range.location = 6;
    NSString *aString = [cString substringWithRange:range];
    if (!aString) {
        aString = @"FF"; // default
    }
     
    // Scan values
    unsigned int r, g, b, a;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:aString] scanHexInt:&a];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:((float)a / 255.0f)];
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
    NSLog(@"Geetest captcha code: %@, result: %@, message: %@", code, result, message);
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
