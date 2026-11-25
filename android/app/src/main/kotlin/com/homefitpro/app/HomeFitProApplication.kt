package com.homefitpro.app

import android.app.Application
import io.flutter.FlutterInjector

class HomeFitProApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Start Flutter initialization here without blocking onCreate() with
        // ensureInitializationComplete(), allowing MainActivity.getFlutterShellArgs()
        // to configure shell flags cleanly.
        try {
            FlutterInjector.instance().flutterLoader().startInitialization(this)
        } catch (_: Throwable) {
        }
    }
}
