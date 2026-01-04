package com.benimsehrim.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import io.radar.sdk.Radar
import java.util.Locale

import org.maplibre.android.MapLibre

@HiltAndroidApp
class BenimSehrimApp : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Force Turkish Locale for consistent string handling (e.g. I/ı, İ/i)
        val locale = Locale("tr", "TR")
        Locale.setDefault(locale)
        
        val config = resources.configuration
        config.setLocale(locale)
        createConfigurationContext(config)

        // Initialize MapLibre
        MapLibre.getInstance(this)

        // Initialize Radar
        Radar.initialize(this, getString(R.string.radar_publishable_key))
    }
}
