package com.asodya.cortex

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.asodya.cortex/native")
            .setMethodCallHandler { call, result ->
                if (call.method == "localizedCountryName") {
                    val countryCode = call.argument<String>("countryCode")
                    if (countryCode.isNullOrBlank()) {
                        result.error("invalid_country_code", "Country code is missing", null)
                    } else {
                        val country = Locale("", countryCode).getDisplayCountry(Locale.getDefault())
                        result.success(country.ifBlank { countryCode })
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
