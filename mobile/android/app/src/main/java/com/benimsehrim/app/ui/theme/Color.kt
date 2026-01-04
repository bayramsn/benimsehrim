package com.benimsehrim.app.ui.theme

import androidx.compose.ui.graphics.Color

// Primary Colors - Neon Green Aesthetic
val Primary = Color(0xFF00E676) // Bright Neon Green
val PrimaryVariant = Color(0xFF00C853)
val PrimaryLight = Color(0xFF69F0AE)
val PrimaryDark = Color(0xFF00331A)

// Secondary Colors - Deep Urban Green
val Secondary = Color(0xFF16251F) // Dark Card Surface
val SecondaryVariant = Color(0xFF0A1A14)
val SecondaryLight = Color(0xFF2A3A32)

// UI Accent Colors
val Success = Color(0xFF00E676)
val Warning = Color(0xFFFFA000)
val Error = Color(0xFFF44336)
val Info = Color(0xFF2196F3)

// Theme Specific Backgrounds
val BackgroundDark = Color(0xFF0A120E) // Main Background
val SurfaceDark = Color(0xFF161F1A) // Card Background
val CardOutline = Color(0xFF222F29)

// Text Colors
val TextPrimary = Color(0xFFFFFFFF)
val TextSecondary = Color(0xFF9BA3AF)
val TextTertiary = Color(0xFF6B7280)
val TextOnPrimary = Color(0xFF00381C) // Dark text on bright green

// Specialty Colors from Design
val TaxiColor = Color(0xFF00C853)
val DeliveryColor = Color(0xFFFFAB40)
val ShoppingColor = Color(0xFF7C4DFF)
val WalletColor = Color(0xFF00E676)

// Gradient Colors
val BrandGradient = listOf(Color(0xFF00E676), Color(0xFF00C853))

// Status Colors
val StatusPending = Color(0xFFFFA000)
val StatusAccepted = Color(0xFF2196F3)
val StatusPreparing = Color(0xFF7C4DFF)
val StatusReady = Color(0xFF00E676)
val StatusOnWay = Color(0xFFFFAB40)
val StatusDelivered = Color(0xFF00E676)
val StatusCancelled = Color(0xFFF44336)

// Category Colors
val CategoryFood = Color(0xFFFF5252)
val CategoryMarket = Color(0xFF00E676)
val CategoryRestaurant = Color(0xFFFFAB40)
val CategoryCafe = Color(0xFF7C4DFF)
val CategoryDessert = Color(0xFFFF4081)

// Shimmer Colors
val ShimmerColorShades = listOf(
    Color(0xFF161F1A),
    Color(0xFF222F29),
    Color(0xFF161F1A)
)

// Legacy Compatibility Aliases
val GradientStart = Primary
val GradientEnd = PrimaryVariant
val BackgroundLight = BackgroundDark
val SurfaceLight = SurfaceDark
