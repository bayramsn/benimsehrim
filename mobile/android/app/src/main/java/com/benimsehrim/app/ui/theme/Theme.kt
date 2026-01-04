package com.benimsehrim.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = darkColorScheme( // Forcing dark theme look even in "light" for this brand
    primary = Primary,
    onPrimary = TextOnPrimary,
    primaryContainer = PrimaryDark,
    onPrimaryContainer = PrimaryLight,
    
    secondary = Secondary,
    onSecondary = TextPrimary,
    secondaryContainer = SecondaryLight,
    onSecondaryContainer = PrimaryLight,
    
    tertiary = Info,
    onTertiary = TextPrimary,
    tertiaryContainer = Info.copy(alpha = 0.2f),
    onTertiaryContainer = Info,
    
    background = BackgroundDark,
    onBackground = TextPrimary,
    
    surface = SurfaceDark,
    onSurface = TextPrimary,
    surfaceVariant = Secondary,
    onSurfaceVariant = TextSecondary,
    
    error = Error,
    onError = TextPrimary,
    errorContainer = Error.copy(alpha = 0.2f),
    onErrorContainer = Error,
    
    outline = CardOutline,
    outlineVariant = SecondaryLight,
)

private val DarkColorScheme = darkColorScheme(
    primary = Primary,
    onPrimary = TextOnPrimary,
    primaryContainer = PrimaryDark,
    onPrimaryContainer = PrimaryLight,
    
    secondary = Secondary,
    onSecondary = TextPrimary,
    secondaryContainer = SecondaryLight,
    onSecondaryContainer = PrimaryLight,
    
    tertiary = Info,
    onTertiary = TextPrimary,
    tertiaryContainer = Info.copy(alpha = 0.3f),
    onTertiaryContainer = Info,
    
    background = BackgroundDark,
    onBackground = TextPrimary,
    
    surface = SurfaceDark,
    onSurface = TextPrimary,
    surfaceVariant = Secondary,
    onSurfaceVariant = TextSecondary,
    
    error = Error,
    onError = TextPrimary,
    errorContainer = Error.copy(alpha = 0.3f),
    onErrorContainer = Error,
    
    outline = CardOutline,
    outlineVariant = SecondaryLight,
)

@Composable
fun BenimSehrimTheme(
    darkTheme: Boolean = true, // Default to true for the new brand identity
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = BackgroundDark.toArgb()
            window.navigationBarColor = BackgroundDark.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = false
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
}
