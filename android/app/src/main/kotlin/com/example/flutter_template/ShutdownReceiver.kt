package com.example.flutter_template

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import org.json.JSONObject
import java.util.Calendar

class ShutdownReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        rescheduleIfNeeded(context)

        // goAsync()로 BroadcastReceiver 실행 시간 제한 해제 (각 방법 대기 시간 확보)
        val pendingResult = goAsync()
        Thread {
            try {
                RebootReceiver.sendRebootLog(context, "[시스템] 자동 종료 실행", "SYS-016")
                performShutdown(context)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun rescheduleIfNeeded(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("flutter.shutdown_schedule", null) ?: return

        try {
            val json = JSONObject(raw)
            if (!json.optBoolean("enabled", false)) return
            val type = json.optString("type", "daily")
            if (type == "specificDate") return

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

    companion object {
        @SuppressLint("PrivateApi")
        fun performShutdown(context: Context) {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
            val isDeviceOwner = dpm.isDeviceOwnerApp(context.packageName)

            RebootReceiver.sendRebootLog(
                context,
                "[시스템] 종료 시도 — DeviceOwner:$isDeviceOwner Android:${Build.VERSION.SDK_INT} Model:${Build.MODEL}",
                "SYS-016"
            )

            // 각 방법 호출 후 3초 대기 — 실제로 종료되면 sleep 도중 프로세스가 끊김
            // 3초 후에도 실행 중이면 다음 방법으로 진행

            // Method 1: PowerManager::class.java 직접 reflection (원시형 boolean 사용)
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                PowerManager::class.java.getMethod("shutdown", Boolean::class.javaPrimitiveType, String::class.java, Boolean::class.javaPrimitiveType)
                    .invoke(pm, false, "userrequested", false)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method1(PM reflection) 호출 — 3초 대기", "SYS-016")
                Thread.sleep(3000)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method1 — 3초 후에도 실행중, 다음 방법 시도", "SYS-016")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method1 실패: ${e.javaClass.simpleName} ${e.message}", "SYS-016")
            }

            // Method 2: setprop sys.powerctl shutdown (AOSP 커널 레벨)
            try {
                Runtime.getRuntime().exec(arrayOf("setprop", "sys.powerctl", "shutdown"))
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method2(setprop sys.powerctl) 호출 — 3초 대기", "SYS-016")
                Thread.sleep(3000)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method2 — 3초 후에도 실행중, 다음 방법 시도", "SYS-016")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method2 실패: ${e.javaClass.simpleName} ${e.message}", "SYS-016")
            }

            // Method 3: ACTION_REQUEST_SHUTDOWN intent
            try {
                val shutdownIntent = Intent("android.intent.action.ACTION_REQUEST_SHUTDOWN").apply {
                    putExtra("android.intent.extra.KEY_CONFIRM", false)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(shutdownIntent)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method3(ACTION_REQUEST_SHUTDOWN) 호출 — 3초 대기", "SYS-016")
                Thread.sleep(3000)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method3 — 3초 후에도 실행중, 다음 방법 시도", "SYS-016")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method3 실패: ${e.javaClass.simpleName} ${e.message}", "SYS-016")
            }

            // Method 4: IPowerManager binder 직접 접근
            try {
                val serviceManagerClass = Class.forName("android.os.ServiceManager")
                val binder = serviceManagerClass.getMethod("getService", String::class.java).invoke(null, "power") as IBinder
                val ipm = Class.forName("android.os.IPowerManager\$Stub")
                    .getMethod("asInterface", IBinder::class.java).invoke(null, binder)
                ipm!!.javaClass.getMethod("shutdown", Boolean::class.java, String::class.java, Boolean::class.java)
                    .invoke(ipm, false, "userrequested", false)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method4(IPowerManager) 호출 — 3초 대기", "SYS-016")
                Thread.sleep(3000)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method4 — 3초 후에도 실행중, 다음 방법 시도", "SYS-016")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method4 실패: ${e.javaClass.simpleName} ${e.message}", "SYS-016")
            }

            // Method 5: shell reboot -p
            try {
                val proc = Runtime.getRuntime().exec(arrayOf("reboot", "-p"))
                val exitCode = proc.waitFor()
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method5(reboot -p) exitCode:$exitCode — 3초 대기", "SYS-016")
                Thread.sleep(3000)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method5 — 3초 후에도 실행중, 다음 방법 시도", "SYS-016")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method5 실패: ${e.javaClass.simpleName} ${e.message}", "SYS-016")
            }

            // Method 6: svc power shutdown
            try {
                val proc = Runtime.getRuntime().exec(arrayOf("/system/bin/svc", "power", "shutdown"))
                val exitCode = proc.waitFor()
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method6(svc power shutdown) exitCode:$exitCode — 3초 대기", "SYS-016")
                Thread.sleep(3000)
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method6 — 3초 후에도 실행중", "SYS-016")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 Method6 실패: ${e.javaClass.simpleName} ${e.message}", "SYS-016")
            }

            // 최종 fallback: lockNow (화면 잠금)
            if (isDeviceOwner) {
                try {
                    dpm.lockNow()
                    RebootReceiver.sendRebootLog(context, "[시스템] 종료 불가 — 모든 방법 실패, lockNow() 화면 잠금으로 대체", "SYS-016")
                } catch (e: Exception) {
                    RebootReceiver.sendRebootLog(context, "[시스템] 종료 전체 실패 (lockNow도 실패): ${e.message}", "SYS-016")
                }
            } else {
                RebootReceiver.sendRebootLog(context, "[시스템] 종료 전체 실패 — DeviceOwner 미등록", "SYS-016")
            }
        }

        fun buildPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, ShutdownReceiver::class.java)
            return PendingIntent.getBroadcast(
                context,
                1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun scheduleShutdown(context: Context, hour: Int, minute: Int, type: String, weekdays: List<Int>, specificDate: String?) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = buildPendingIntent(context)

            val triggerMs = when (type) {
                "weekly" -> RebootReceiver.nextWeeklyTrigger(hour, minute, weekdays)
                "specificDate" -> {
                    val parts = specificDate?.split("-") ?: return
                    if (parts.size != 3) return
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, parts[0].toInt())
                        set(Calendar.MONTH, parts[1].toInt() - 1)
                        set(Calendar.DAY_OF_MONTH, parts[2].toInt())
                        set(Calendar.HOUR_OF_DAY, hour)
                        set(Calendar.MINUTE, minute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    cal.timeInMillis
                }
                else -> RebootReceiver.nextDailyTrigger(hour, minute)
            }

            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pendingIntent)
        }

        fun cancelShutdown(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(buildPendingIntent(context))
        }
    }
}
