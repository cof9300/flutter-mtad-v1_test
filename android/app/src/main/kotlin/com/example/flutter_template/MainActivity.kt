package com.example.flutter_template

import android.app.AlarmManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private val channel = "kiosk_lock_channel"
    private val rebootChannel = "reboot_channel"
    private val shutdownChannel = "shutdown_channel"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponentName: ComponentName

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponentName = ComponentName(this, DeviceAdminReceiver::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        enforceKioskSystemUi()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceOwner" -> {
                    result.success(devicePolicyManager.isDeviceOwnerApp(packageName))
                }
                "startKiosk" -> {
                    enforceKioskSystemUi()
                    if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                        try {
                            devicePolicyManager.setLockTaskPackages(
                                adminComponentName,
                                arrayOf(packageName)
                            )
                            startLockTask()
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                "stopKiosk" -> {
                    if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                        try {
                            stopLockTask()
                        } catch (_: Exception) {}
                    }
                    enforceKioskSystemUi()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        setupShutdownChannel(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            rebootChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleReboot" -> {
                    try {
                        val json = JSONObject(call.arguments as String)
                        scheduleReboot(json)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR_SCHEDULE", e.message, null)
                    }
                }
                "cancelReboot" -> {
                    try {
                        cancelReboot()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR_CANCEL", e.message, null)
                    }
                }
                "rebootNow" -> {
                    if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                        // 로그 전송이 완료된 후 재부팅해야 로그가 서버에 도달한다.
                        val logThread = Thread {
                            RebootReceiver.sendRebootLog(this, "[시스템] 수동 재부팅 실행 (관리자)", "SYS-013")
                        }
                        logThread.start()
                        try { logThread.join(4000) } catch (_: InterruptedException) {}

                        // 재부팅 성공 감지용 플래그 저장 (앱 재시작 시 Flutter에서 읽어 SYS-015 로그 전송)
                        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            .edit()
                            .putString("flutter.last_reboot_type", "manual")
                            .apply()

                        try {
                            devicePolicyManager.reboot(adminComponentName)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR_REBOOT", e.message, null)
                        }
                    } else {
                        result.error("ERR_NOT_OWNER", "Device Owner 권한 없음", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleReboot(json: JSONObject) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = RebootReceiver.buildPendingIntent(this)
        val type = json.optString("type", "daily")
        val hour = json.optInt("hour", 3)
        val minute = json.optInt("minute", 0)

        val triggerMs = when (type) {
            "weekly" -> {
                val arr = json.optJSONArray("weekdays")
                val days = mutableListOf<Int>()
                if (arr != null) for (i in 0 until arr.length()) days.add(arr.getInt(i))
                RebootReceiver.nextWeeklyTrigger(hour, minute, days)
            }
            "specificDate" -> {
                val dateStr = json.optString("specificDate", "")
                val parts = dateStr.split("-")
                if (parts.size == 3) {
                    val cal = java.util.Calendar.getInstance().apply {
                        set(java.util.Calendar.YEAR, parts[0].toInt())
                        set(java.util.Calendar.MONTH, parts[1].toInt() - 1)
                        set(java.util.Calendar.DAY_OF_MONTH, parts[2].toInt())
                        set(java.util.Calendar.HOUR_OF_DAY, hour)
                        set(java.util.Calendar.MINUTE, minute)
                        set(java.util.Calendar.SECOND, 0)
                        set(java.util.Calendar.MILLISECOND, 0)
                    }
                    cal.timeInMillis
                } else {
                    RebootReceiver.nextDailyTrigger(hour, minute)
                }
            }
            else -> RebootReceiver.nextDailyTrigger(hour, minute)
        }

        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pendingIntent)
    }

    private fun cancelReboot() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(RebootReceiver.buildPendingIntent(this))
    }

    private fun setupShutdownChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shutdownChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleShutdown" -> {
                    try {
                        val json = JSONObject(call.arguments as String)
                        val type = json.optString("type", "daily")
                        val hour = json.optInt("hour", 23)
                        val minute = json.optInt("minute", 0)
                        val arr = json.optJSONArray("weekdays")
                        val days = mutableListOf<Int>()
                        if (arr != null) for (i in 0 until arr.length()) days.add(arr.getInt(i))
                        val specificDate = json.optString("specificDate", null)
                        ShutdownReceiver.scheduleShutdown(this, hour, minute, type, days, specificDate)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR_SCHEDULE_SHUTDOWN", e.message, null)
                    }
                }
                "cancelShutdown" -> {
                    try {
                        ShutdownReceiver.cancelShutdown(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR_CANCEL_SHUTDOWN", e.message, null)
                    }
                }
                "shutdownNow" -> {
                    val logThread = Thread {
                        RebootReceiver.sendRebootLog(this, "[시스템] 수동 종료 실행 (관리자)", "SYS-016")
                    }
                    logThread.start()
                    try { logThread.join(4000) } catch (_: InterruptedException) {}
                    ShutdownReceiver.performShutdown(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) enforceKioskSystemUi()
    }

    override fun onResume() {
        super.onResume()
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        enforceKioskSystemUi()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    override fun onStart() {
        super.onStart()
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    override fun onPostResume() {
        super.onPostResume()
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    private fun enforceKioskSystemUi() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.systemBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                )
        }
    }
}
