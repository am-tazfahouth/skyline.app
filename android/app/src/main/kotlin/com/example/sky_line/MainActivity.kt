package com.example.sky_line

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sky_line/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openLocationSettings" -> {
                        result.success(openSettings(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                    }
                    "openAppSettings" -> {
                        result.success(
                            openSettings(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openSettings(action: String, data: Uri? = null): Boolean {
        return try {
            val intent = if (data != null) Intent(action, data) else Intent(action)
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK or
                    Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
            )
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
