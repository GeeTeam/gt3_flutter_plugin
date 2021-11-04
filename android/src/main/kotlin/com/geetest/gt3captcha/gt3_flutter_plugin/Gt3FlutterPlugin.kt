package com.geetest.gt3captcha.gt3_flutter_plugin

import android.app.Activity
import android.os.Build
import android.util.Log
import com.geetest.sdk.GT3ConfigBean
import com.geetest.sdk.GT3ErrorBean
import com.geetest.sdk.GT3GeetestUtils
import com.geetest.sdk.GT3Listener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

class Gt3FlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel

    private lateinit var gt3GeetestUtils: GT3GeetestUtils
    private lateinit var gt3ConfigBean: GT3ConfigBean

    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "gt3_flutter_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startCaptcha" -> {
                startCaptchaInner(call, result)
            }
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        geetestInit()
    }

    override fun onDetachedFromActivity() {
        gt3GeetestUtils.destory()
        this.activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        gt3GeetestUtils.destory()
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    private fun startCaptchaInner(call: MethodCall, result: Result) {
        val args: Map<String, Any> = call.arguments()
        Log.i(TAG, "Geetest captcha register params: $args")

        if (args.containsKey("gt") &&
            args.containsKey("challenge") &&
            args.containsKey("success")
        ) {
            gt3GeetestUtils.startCustomFlow()
            val geetestId = args["gt"]
            val geetestChallenge = args["challenge"]
            val geetestSuccess = if (args["success"] == null) 0 else 1
            gt3ConfigBean.api1Json =
                JSONObject("{\"success\":$geetestSuccess,\"challenge\":\"$geetestChallenge\",\"gt\":\"$geetestId\",\"new_captcha\":true}")
            gt3GeetestUtils.getGeetest()
        } else {
            val ret: Map<String, String> = mapOf(
                "initWithDomain" to "com.geetest.gt3.flutter",
                "code" to "-1",
                "userInfo" to "Register params parse invalid"
            )
            channel.invokeMethod("onError", ret)
        }
    }

    private fun geetestInit() {
        gt3GeetestUtils = GT3GeetestUtils(activity)
        gt3ConfigBean = GT3ConfigBean()
        gt3ConfigBean.apply {
            pattern = 1
            listener = object : GT3Listener() {
                override fun onDialogReady(duration: String?) {
                    channel.invokeMethod("onShow", mapOf("show" to "1"))
                }

                override fun onDialogResult(result: String?) {
                    gt3GeetestUtils.showSuccessDialog()
                }

                override fun onReceiveCaptchaCode(p0: Int) {
                    Log.i(TAG, "Geetest captcha code: $p0")
                    channel.invokeMethod("onResult", mapOf("code" to "$p0"))
                }

                override fun onStatistics(p0: String?) {}

                override fun onClosed(p0: Int) {
                    channel.invokeMethod("onClose", mapOf("close" to "$p0"))
                }

                override fun onSuccess(p0: String?) {}

                override fun onFailed(p0: GT3ErrorBean?) {
                    val ret = mapOf(
                        "code" to p0?.errorCode,
                        "description" to p0?.errorDesc
                    )
                    channel.invokeMethod("onError", ret)
                }

                override fun onButtonClick() {}
            }
        }
        gt3GeetestUtils.init(gt3ConfigBean)
    }

    private companion object {
        const val TAG = "Gt3FlutterPlugin"
    }
}
