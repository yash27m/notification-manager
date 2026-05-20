// android/app/src/main/kotlin/com/example/notification_manager/MainActivity.kt
package com.example.notification_manager

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.storage.StorageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.notification_manager/permissions"
    private val REQUEST_WHATSAPP_FOLDER = 1001
    private var pendingResult: MethodChannel.Result? = null

    // OEMs with autostart managers
    private val autostartManufacturers = setOf(
        "xiaomi", "redmi", "poco", "oppo", "realme", "oneplus",
        "vivo", "iqoo", "huawei", "honor", "asus",
        "letv", "leeco", "meizu", "tecno", "infinix",
    )

    private val autostartIntents: List<Intent> by lazy {
        listOf(
            Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
            Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
            Intent().setComponent(ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")),
            Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity")),
            Intent().setComponent(ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity")),
            Intent().setComponent(ComponentName("com.meizu.safe", "com.meizu.safe.security.SHOW_APPSEC")),
            Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.itel.autobootmanager.activity.AutoBootMgrActivity")),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── EventChannel: notification streaming ──
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NotificationListener.CHANNEL_NAME)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationListener.setEventSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    NotificationListener.setEventSink(null)
                }
            })

        // ── MethodChannel: permissions + WhatsApp SAF ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAutostartAvailable" -> result.success(isAutostartAvailable())

                    "openAutostartSettings" -> {
                        val intent = findAutostartIntent()
                        if (intent != null) {
                            try { intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK); startActivity(intent); result.success(true) }
                            catch (_: Exception) { result.success(false) }
                        } else result.success(false)
                    }

                    "isNotificationListenerEnabled" -> result.success(isNotificationListenerEnabled())

                    "openNotificationListenerSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success(true)
                    }

                    "hasWhatsAppFolderAccess" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        result.success(hasWhatsAppFolderAccess(pkg))
                    }

                    "requestWhatsAppFolderAccess" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        pendingResult = result
                        requestWhatsAppFolderAccess(pkg)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Autostart ──

    private fun isAutostartAvailable(): Boolean {
        val mfr = Build.MANUFACTURER.lowercase()
        if (!autostartManufacturers.any { mfr.contains(it) }) return false
        return findAutostartIntent() != null
    }

    private fun findAutostartIntent(): Intent? {
        for (intent in autostartIntents) {
            val pkg = intent.component?.packageName ?: continue
            try { packageManager.getPackageInfo(pkg, 0); if (intent.resolveActivity(packageManager) != null) return intent }
            catch (_: Exception) { continue }
        }
        return null
    }

    // ── Notification Listener ──

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return flat.contains(ComponentName(this, NotificationListener::class.java).flattenToString())
    }

    // ── WhatsApp SAF ──

    private fun waFolderPath(pkg: String): String = when (pkg) {
        "com.whatsapp" -> "Android%2Fmedia%2Fcom.whatsapp%2FWhatsApp"
        "com.whatsapp.w4b" -> "Android%2Fmedia%2Fcom.whatsapp.w4b%2FWhatsApp Business"
        else -> ""
    }

    private fun hasWhatsAppFolderAccess(pkg: String): Boolean {
        val path = waFolderPath(pkg)
        return contentResolver.persistedUriPermissions.any { it.uri.toString().contains(path) && it.isReadPermission }
    }

    private fun requestWhatsAppFolderAccess(pkg: String) {
        val path = waFolderPath(pkg)
        if (path.isEmpty()) { pendingResult?.success(false); pendingResult = null; return }
        try {
            val sm = getSystemService(STORAGE_SERVICE) as StorageManager
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                sm.primaryStorageVolume.createOpenDocumentTreeIntent().apply {
                    val uri = getParcelableExtra<Uri>("android.provider.extra.INITIAL_URI")
                    putExtra("android.provider.extra.INITIAL_URI", Uri.parse(uri.toString().replace("/root/", "/document/") + "%3A$path"))
                }
            } else Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            startActivityForResult(intent, REQUEST_WHATSAPP_FOLDER)
        } catch (_: Exception) {
            try { startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), REQUEST_WHATSAPP_FOLDER) }
            catch (_: Exception) { pendingResult?.success(false); pendingResult = null }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_WHATSAPP_FOLDER) {
            if (resultCode == RESULT_OK && data?.data != null) {
                contentResolver.takePersistableUriPermission(data.data!!, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                pendingResult?.success(true)
            } else pendingResult?.success(false)
            pendingResult = null
        }
    }
}