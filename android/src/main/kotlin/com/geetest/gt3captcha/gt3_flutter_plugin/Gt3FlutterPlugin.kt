package com.geetest.gt3captcha.gt3_flutter_plugin

import android.app.Activity
import android.util.Log
import com.geetest.sdk.GT3ConfigBean
import com.geetest.sdk.GT3ErrorBean
import com.geetest.sdk.GT3GeetestUtils
import com.geetest.sdk.GT3Listener
import com.geetest.sdk.utils.GT3Protocol
import com.geetest.sdk.utils.GT3ServiceNode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import kotlin.math.absoluteValue

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
            "initWithConfig" -> {
                initWithConfigInner(call)
            }
            "startCaptcha" -> {
                startCaptchaInner(call)
            }
            "configurationChanged" -> {
                configurationChanged()
            }
            "getPlatformVersion" -> {
                result.success(GT3GeetestUtils.getVersion())
            }
            "close" -> {
                gt3GeetestUtils.dismissGeetestDialog()
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
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    private fun configurationChanged() {
        gt3GeetestUtils.changeDialogLayout()
    }

    private fun initWithConfigInner(call: MethodCall) {
        val args: Map<String, Any>? = call.arguments()
        Log.i(TAG, "Geetest initWithConfig configs: $args")
        args?.run {
            if (containsKey("timeout")) {
                val value = this["timeout"] as? Double ?: 8.0
                gt3ConfigBean.timeout = value.toInt() * 1000
            }
            if (containsKey("language")) {
                val value = this["language"] as? String ?: "zh"
                gt3ConfigBean.lang = value
            }
            if (containsKey("cornerRadius")) {
                val value = this["cornerRadius"] as? Double ?: 2.0
                val valueInt = value.toInt()
                gt3ConfigBean.corners = valueInt.absoluteValue
                gt3ConfigBean.dialogOffsetY = valueInt
            }
            if (containsKey("serviceNode")) {
                val value = this["serviceNode"] as? Int ?: 0
                if (value == 0) {
                    gt3ConfigBean.gt3ServiceNode = GT3ServiceNode.NODE_CHINA
                } else if (value == 1) {
                    gt3ConfigBean.gt3ServiceNode = GT3ServiceNode.NODE_IPV6
                }
            }
            if (containsKey("bgInteraction")) {
                val value = this["bgInteraction"] as? Boolean ?: true
                gt3ConfigBean.isCanceledOnTouchOutside = value
            }
        }
        gt3ConfigBean.getRequestProtocol = GT3Protocol.HTTPS
        gt3GeetestUtils.init(gt3ConfigBean)
    }

    private fun startCaptchaInner(call: MethodCall) {
        val args: Map<String, Any>? = call.arguments()
        Log.i(TAG, "Geetest captcha register params: $args")

        if (args == null) {
            val ret = hashMapOf(
                "code" to "-1",
                "description" to "Register params parse invalid"
            )
            channel.invokeMethod("onError", ret)
            return
        }

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
            val ret = hashMapOf(
                "code" to "-1",
                "description" to "Register params parse invalid"
            )
            channel.invokeMethod("onError", ret)
        }
    }

    private fun geetestInit() {
        gt3GeetestUtils = GT3GeetestUtils(activity)
        gt3ConfigBean = GT3ConfigBean()
        var code = -1
        gt3ConfigBean.apply {
            pattern = 1
            listener = object : GT3Listener() {
                override fun onDialogReady(duration: String?) {
                    channel.invokeMethod("onShow", hashMapOf("show" to "1"))
                }

                override fun onDialogResult(result: String?) {
                    // 将 result 转为 map
                    val map = hashMapOf<String, String>()
                    try {
                        val jsonObject = JSONObject(result)
                        val keys = jsonObject.keys()
                        while (keys.hasNext()) {
                            val key = keys.next()
                            map[key] = jsonObject.optString(key)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                    channel.invokeMethod(
                        "onResult", hashMapOf(
                            "code" to "$code",
                            "result" to map
                        )
                    )
                    gt3GeetestUtils.showSuccessDialog()
                }

                override fun onReceiveCaptchaCode(p0: Int) {
                    code = p0
                }

                override fun onClosed(p0: Int) {
                    channel.invokeMethod("onClose", hashMapOf("close" to "$p0"))
                }

                override fun onFailed(p0: GT3ErrorBean?) {
                    val ret = hashMapOf(
                        "code" to "${p0?.errorCode}",
                        "description" to "${p0?.errorDesc}"
                    )
                    channel.invokeMethod("onError", ret)
                }

                override fun onStatistics(p0: String?) {}
                override fun onSuccess(p0: String?) {}
                override fun onButtonClick() {}
            }
        }
    }

    private companion object {
        const val TAG = "Gt3FlutterPlugin"
    }
}
