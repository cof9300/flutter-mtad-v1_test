package com.example.flutter_template

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class RebootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, DeviceAdminReceiver::class.java)

        if (!dpm.isDeviceOwnerApp(context.packageName)) return

        // 다음 알람 재스케줄 (매일/요일별)
        rescheduleIfNeeded(context)

        // 로그 전송이 완료된 후에 재부팅해야 로그가 서버에 도달한다.
        // sendRebootLog는 blocking HTTP이므로 별도 Thread에서 실행 후 join으로 대기한다.
        val logThread = Thread {
            sendRebootLog(context, "[시스템] 자동 재부팅 실행", "SYS-012")
        }
        logThread.start()
        try { logThread.join(4000) } catch (_: InterruptedException) {}

        // 재부팅 성공 감지용 플래그 저장 (앱 재시작 시 Flutter에서 읽어 SYS-014 로그 전송)
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putString("flutter.last_reboot_type", "auto")
            .apply()

        try {
            dpm.reboot(adminComponent)
        } catch (_: Exception) {}
    }

    private fun rescheduleIfNeeded(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("flutter.reboot_schedule", null) ?: return

        try {
            val json = JSONObject(raw)
            if (!json.optBoolean("enabled", false)) return
            val type = json.optString("type", "daily")
            if (type == "specificDate") return // 단일날짜는 재스케줄 불필요

            val hour = json.optInt("hour", 3)
            val minute = json.optInt("minute", 0)

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = buildPendingIntent(context)

            val triggerMs = when (type) {
                "weekly" -> {
                    val weekdays = json.optJSONArray("weekdays")
                    val days = mutableListOf<Int>()
                    if (weekdays != null) {
                        for (i in 0 until weekdays.length()) days.add(weekdays.getInt(i))
                    }
                    nextWeeklyTrigger(hour, minute, days)
                }
                else -> nextDailyTrigger(hour, minute) // daily
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerMs,
                pendingIntent
            )
        } catch (_: Exception) {}
    }

    companion object {
        private const val LOG_URL = "http://43.203.201.107:8000/api/logs/batch"

        /**
         * 재부팅 로그를 서버에 동기(blocking) 방식으로 전송한다.
         * 반드시 메인 스레드가 아닌 별도 Thread에서 호출해야 한다.
         * 재부팅 직전에 호출되므로 전송 완료를 보장하기 위해 비동기 Thread를 쓰지 않는다.
         */
        fun sendRebootLog(context: Context, message: String, errorCode: String) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val kioskId = prefs.getString("flutter.kiosk_id", null)
            val model = Build.MODEL.replace(" ", "_")
            val buildId = Build.ID.replace(" ", "_")
            val deviceId = if (!kioskId.isNullOrEmpty()) {
                "device_ID_${kioskId}_${model}_${buildId}"
            } else {
                "device_ID_${model}_${buildId}"
            }

            val appVersion = try {
                val pInfo = context.packageManager.getPackageInfo(context.packageName, 0)
                pInfo.versionName ?: "unknown"
            } catch (_: Exception) { "unknown" }

            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.getDefault())
            sdf.timeZone = TimeZone.getTimeZone("Asia/Seoul")
            val timestamp = sdf.format(Date())

            val logEntry = JSONObject().apply {
                put("timestamp", timestamp)
                put("level", "INFO")
                put("message", message)
                put("appVersion", "v$appVersion")
                put("errorCode", errorCode)
                put("severity", "INFO")
                if (!kioskId.isNullOrEmpty()) put("kioskId", kioskId)
            }

            val payload = JSONObject().apply {
                put("device_id", deviceId)
                put("logs", JSONArray().put(logEntry))
            }

            // 이 함수는 이미 별도 Thread에서 호출되므로 직접 blocking HTTP 전송한다.
            try {
                val conn = URL(LOG_URL).openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.setRequestProperty("accept", "application/json")
                conn.doOutput = true
                conn.connectTimeout = 3000
                conn.readTimeout = 3000
                conn.outputStream.use { it.write(payload.toString().toByteArray()) }
                conn.responseCode
                conn.disconnect()
            } catch (_: Exception) {}
        }

        fun buildPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, RebootReceiver::class.java)
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun nextDailyTrigger(hour: Int, minute: Int): Long {
            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_MONTH, 1)
            }
            return cal.timeInMillis
        }

        fun nextWeeklyTrigger(hour: Int, minute: Int, weekdays: List<Int>): Long {
            if (weekdays.isEmpty()) return nextDailyTrigger(hour, minute)

            // weekdays: 1=월 ~ 7=일 → Calendar: 1=일, 2=월 ~ 7=토
            val now = Calendar.getInstance()
            var best: Long = Long.MAX_VALUE

            for (day in weekdays) {
                val calDay = if (day == 7) Calendar.SUNDAY else day + 1
                val cal = Calendar.getInstance().apply {
                    set(Calendar.DAY_OF_WEEK, calDay)
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    if (timeInMillis <= now.timeInMillis) add(Calendar.WEEK_OF_YEAR, 1)
                }
                if (cal.timeInMillis < best) best = cal.timeInMillis
            }
            return if (best == Long.MAX_VALUE) nextDailyTrigger(hour, minute) else best
        }
    }
}
