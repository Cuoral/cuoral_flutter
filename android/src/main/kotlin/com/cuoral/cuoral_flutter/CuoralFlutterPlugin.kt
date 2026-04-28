package com.cuoral.cuoral_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

/** CuoralFlutterPlugin */
class CuoralFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var context: Context? = null
  private var activityBinding: ActivityPluginBinding? = null
  
  // Crash tracking
  private var sessionId: String? = null
  private var publicKey: String? = null
  private var defaultHandler: Thread.UncaughtExceptionHandler? = null
  private var isHandlingCrash = false
  
  // Screen recording
  private var screenRecorder: ScreenRecorder? = null
  private var pendingRecordingResult: Result? = null
  private val SCREEN_CAPTURE_REQUEST_CODE = 1001
  
  companion object {
    private const val CRASH_ENDPOINT = "https://api.cuoral.com/customer-intelligence/console-error"
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cuoral_flutter")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${Build.VERSION.RELEASE}")
      }
      "initializeCrashTracking" -> {
        sessionId = call.argument<String>("sessionId")
        publicKey = call.argument<String>("publicKey")
        initializeCrashTracking()
        result.success(true)
      }
      "isRecordingAvailable" -> {
        result.success(true) // Always available on Android
      }
      "startRecording" -> {
        val withAudio = call.argument<Boolean>("withAudio") ?: true
        startRecording(withAudio, result)
      }
      "stopRecording" -> {
        stopRecording(result)
      }
      "isRecording" -> {
        result.success(screenRecorder?.isRecording() ?: false)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }
  
  // ActivityAware implementation
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    binding.addActivityResultListener(this)
  }
  
  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding?.removeActivityResultListener(this)
    activity = null
    activityBinding = null
  }
  
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    binding.addActivityResultListener(this)
  }
  
  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(this)
    activity = null
    activityBinding = null
  }
  
  // Crash tracking implementation
  private fun initializeCrashTracking() {
    try {
      // Save the default handler
      defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
      
      // Set custom handler
      Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
        handleCrash(thread, throwable)
      }
    } catch (_: Exception) {
    }
  }
  
  private fun handleCrash(thread: Thread, throwable: Throwable) {
    if (isHandlingCrash) return
    isHandlingCrash = true
    try {
      sendCrashReport(throwable, thread.name)
    } catch (_: Exception) {
    } finally {
      defaultHandler?.uncaughtException(thread, throwable)
    }
  }
  
  private fun sendCrashReport(throwable: Throwable, threadName: String) {
    try {
      val deviceInfo = mapOf(
        "device_model" to "${Build.MANUFACTURER} ${Build.MODEL}",
        "os_version" to Build.VERSION.RELEASE,
        "sdk_version" to Build.VERSION.SDK_INT.toString(),
        "thread" to threadName,
        "error_type" to "native_crash"
      )
      
      val crashData = JSONObject().apply {
        put("message", throwable.message ?: throwable.toString())
        put("stack_trace", getStackTraceString(throwable))
        put("log_level", "error")
        put("url", "native://android")
        put("session_id", sessionId)
        put("source", "mobile")
        put("console_metadata", JSONObject(deviceInfo))
      }
      
      val array = org.json.JSONArray()
      array.put(crashData)
      
      sendHttpRequestSync(CRASH_ENDPOINT, array.toString(), 2000)
    } catch (_: Exception) {
    }
  }
  
  private fun getStackTraceString(throwable: Throwable): String {
    val sw = java.io.StringWriter()
    val pw = java.io.PrintWriter(sw)
    throwable.printStackTrace(pw)
    return sw.toString()
  }
  
  private fun sendHttpRequestSync(endpoint: String, jsonBody: String, timeoutMs: Int) {
    var connection: HttpURLConnection? = null
    try {
      val url = URL(endpoint)
      connection = url.openConnection() as HttpURLConnection
      connection.requestMethod = "POST"
      connection.setRequestProperty("Content-Type", "application/json")
      if (publicKey != null) {
        connection.setRequestProperty("x-org-id", publicKey)
      }
      connection.connectTimeout = timeoutMs
      connection.readTimeout = timeoutMs
      connection.doOutput = true
      
      val writer = OutputStreamWriter(connection.outputStream)
      writer.write(jsonBody)
      writer.flush()
      writer.close()
      
      connection.responseCode
    } catch (_: Exception) {
    } finally {
      connection?.disconnect()
    }
  }
  
  // Screen recording implementation
  private fun startRecording(withAudio: Boolean, result: Result) {
    try {
      val currentActivity = activity
      if (currentActivity == null) {
        result.error("NO_ACTIVITY", "Activity not available", null)
        return
      }
      
      val currentContext = context
      if (currentContext == null) {
        result.error("NO_CONTEXT", "Context not available", null)
        return
      }
      
      pendingRecordingResult = result
      
      // Request screen capture permission
      val projectionManager = currentContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
      
      val captureIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        // Android 14+: Force entire screen capture
        val config = android.media.projection.MediaProjectionConfig.createConfigForDefaultDisplay()
        projectionManager.createScreenCaptureIntent(config)
      } else {
        // Older versions
        projectionManager.createScreenCaptureIntent()
      }
      
      currentActivity.startActivityForResult(captureIntent, SCREEN_CAPTURE_REQUEST_CODE)
    } catch (e: Exception) {
      result.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
      pendingRecordingResult = null
    }
  }
  
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == SCREEN_CAPTURE_REQUEST_CODE) {
      val result = pendingRecordingResult
      pendingRecordingResult = null
      
      if (resultCode == Activity.RESULT_OK && data != null) {
        try {
          val currentContext = context
          if (currentContext == null) {
            result?.error("NO_CONTEXT", "Context not available", null)
            return true
          }
          
          // Initialize screen recorder
          screenRecorder = ScreenRecorder(currentContext, resultCode, data)
          screenRecorder?.startRecording()
          
          result?.success(true)
        } catch (e: Exception) {
          result?.error("RECORDING_ERROR", "Failed to initialize recording: ${e.message}", null)
        }
      } else {
        result?.error("PERMISSION_DENIED", "Screen recording permission denied", null)
      }
      return true
    }
    return false
  }
  
  private fun stopRecording(result: Result) {
    try {
      val recorder = screenRecorder
      if (recorder == null) {
        result.error("NOT_RECORDING", "No active recording", null)
        return
      }
      
      val filePath = recorder.stopRecording()
      screenRecorder = null
      
      result.success(filePath)
    } catch (e: Exception) {
      result.error("STOP_ERROR", "Failed to stop recording: ${e.message}", null)
    }
  }
}
