package com.example.flutter_template

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import org.json.JSONObject

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val isBootCompleted = action == Intent.ACTION_BOOT_COMPLETED ||
                action == "android.intent.action.LOCKED_BOOT_COMPLETED"
        val isPackageReplaced = action == Intent.ACTION_MY_PACKAGE_REPLACED

        if (!isBootCompleted && !isPackageReplaced) return

        // AlarmManager 알람은 시스템 재부팅 시에만 초기화된다 (앱 업데이트 시에는 유지됨).
        // 따라서 BOOT_COMPLETED 시에만 재부팅/종료 스케줄을 다시 등록한다.
        if (isBootCompleted) {
            restoreRebootAlarmIfNeeded(context)
            restoreShutdownAlarmIfNeeded(context)
        }

        // 시스템이 완전히 준비될 때까지 잠시 대기 후 앱 실행
        // (일부 Samsung 기기에서 즉시 실행 시 실패하는 경우 방지)
        val delayMs = if (action == "android.intent.action.LOCKED_BOOT_COMPLETED") 3000L else 1500L

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val i = Intent(context, MainActivity::class.java).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                    )
                }
                context.startActivity(i)
            } catch (_: Exception) {
                // 실패 시 무시 — 사용자가 직접 앱을 실행해야 함
            }
        }, delayMs)
    }

    private fun restoreRebootAlarmIfNeeded(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.reboot_schedule", null) ?: return

            val json = JSONObject(raw)
            if (!json.optBoolean("enabled", false)) return

            val type = json.optString("type", "daily")
            val hour = json.optInt("hour", 3)
            val minute = json.optInt("minute", 0)

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = RebootReceiver.buildPendingIntent(context)

            val triggerMs = when (type) {
                "specificDate" -> {
                    // 단일 날짜는 이미 지난 경우 재등록 불필요
                    val dateStr = json.optString("specificDate", "")
                    val parts = dateStr.split("-")
                    if (parts.size != 3) return
                    val cal = java.util.Calendar.getInstance().apply {
                        set(java.util.Calendar.YEAR, parts[0].toInt())
                        set(java.util.Calendar.MONTH, parts[1].toInt() - 1)
                        set(java.util.Calendar.DAY_OF_MONTH, parts[2].toInt())
                        set(java.util.Calendar.HOUR_OF_DAY, hour)
                        set(java.util.Calendar.MINUTE, minute)
                        set(java.util.Calendar.SECOND, 0)
                        set(java.util.Calendar.MILLISECOND, 0)
                    }
                    if (cal.timeInMillis <= System.currentTimeMillis()) return
                    cal.timeInMillis
                }
                "weekly" -> {
                    val weekdays = json.optJSONArray("weekdays")
                    val days = mutableListOf<Int>()
                    if (weekdays != null) {
                        for (i in 0 until weekdays.length()) days.add(weekdays.getInt(i))
                    }
                    RebootReceiver.nextWeeklyTrigger(hour, minute, days)
                }
                else -> RebootReceiver.nextDailyTrigger(hour, minute) // daily
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerMs,
                pendingIntent
            )
        } catch (_: Exception) {}
    }

    private fun restoreShutdownAlarmIfNeeded(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.shutdown_schedule", null) ?: return

            val json = JSONObject(raw)
            if (!json.optBoolean("enabled", false)) return

            val type = json.optString("type", "daily")
            val hour = json.optInt("hour", 23)
            val minute = json.optInt("minute", 0)

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = ShutdownReceiver.buildPendingIntent(context)

            val triggerMs = when (type) {
                "specificDate" -> {
                    val dateStr = json.optString("specificDate", "")
                    val parts = dateStr.split("-")
                    if (parts.size != 3) return
                    val cal = java.util.Calendar.getInstance().apply {
                        set(java.util.Calendar.YEAR, parts[0].toInt())
                        set(java.util.Calendar.MONTH, parts[1].toInt() - 1)
                        set(java.util.Calendar.DAY_OF_MONTH, parts[2].toInt())
                        set(java.util.Calendar.HOUR_OF_DAY, hour)
                        set(java.util.Calendar.MINUTE, minute)
                        set(java.util.Calendar.SECOND, 0)
                        set(java.util.Calendar.MILLISECOND, 0)
                    }
                    if (cal.timeInMillis <= System.currentTimeMillis()) return
                    cal.timeInMillis
                }
                "weekly" -> {
                    val weekdays = json.optJSONArray("weekdays")
                    val days = mutableListOf<Int>()
                    if (weekdays != null) {
                        for (i in 0 until weekdays.length()) days.add(weekdays.getInt(i))
                    }
                    RebootReceiver.nextWeeklyTrigger(hour, minute, days)
                }
                else -> RebootReceiver.nextDailyTrigger(hour, minute)
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerMs,
                pendingIntent
            )
        } catch (_: Exception) {}
    }
}
