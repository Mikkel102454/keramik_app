package nu.miguel.claydock

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var billing: ClayDockBilling? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        billing = ClayDockBilling(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "claydock/billing"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "claydock/notifications").setMethodCallHandler { call, result ->
            if (call.method == "settings") {
                startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                result.success(null)
            } else result.notImplemented()
        }
    }
    override fun onDestroy() { billing?.close(); super.onDestroy() }
}
