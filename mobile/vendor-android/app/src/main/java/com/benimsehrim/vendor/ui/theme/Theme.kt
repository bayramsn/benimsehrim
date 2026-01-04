package com.benimsehrim.vendor.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// Vendor Green Theme
private val VendorGreen = Color(0xFF006E24)
private val VendorGreenLight = Color(0xFF4CAF50)
private val VendorGreenDark = Color(0xFF003D12)

private val LightColorScheme = lightColorScheme(
    primary = VendorGreen,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFB8F5B8),
    onPrimaryContainer = VendorGreenDark,
    secondary = Color(0xFF526350),
    onSecondary = Color.White,
    background = Color(0xFFFCFDF7),
    onBackground = Color(0xFF1A1C19),
    surface = Color.White,
    onSurface = Color(0xFF1A1C19),
    surfaceVariant = Color(0xFFF0F5ED),
    onSurfaceVariant = Color(0xFF424940),
)

private val DarkColorScheme = darkColorScheme(
    primary = VendorGreenLight,
    onPrimary = Color(0xFF003909),
    primaryContainer = VendorGreen,
    onPrimaryContainer = Color(0xFFB8F5B8),
    secondary = Color(0xFFBACAB6),
    onSecondary = Color(0xFF253424),
    background = Color(0xFF1A1C19),
    onBackground = Color(0xFFE2E3DE),
    surface = Color(0xFF1A1C19),
    onSurface = Color(0xFFE2E3DE),
    surfaceVariant = Color(0xFF424940),
    onSurfaceVariant = Color(0xFFC2C9BD),
)

@Composable
fun VendorTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography(),
        content = content
    )
}
