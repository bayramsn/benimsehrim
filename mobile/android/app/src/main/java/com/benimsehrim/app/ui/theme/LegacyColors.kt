package com.benimsehrim.app.ui.theme

import androidx.compose.ui.graphics.Color

// Legacy color mappings for backward compatibility
// TODO: Replace these with new color system gradually

val Green40 = Success
val Green60 = Success
val Green80 = Success
val Green90 = Success.copy(alpha = 0.9f)
val Green10 = Success.copy(alpha = 0.1f)
val Green20 = Success.copy(alpha = 0.2f)
val Green30 = Success.copy(alpha = 0.3f)

val Orange40 = Secondary
val Orange60 = SecondaryVariant
val Orange80 = SecondaryLight
val Orange90 = SecondaryLight.copy(alpha = 0.9f)
val Orange10 = Secondary.copy(alpha = 0.1f)
val Orange20 = Secondary.copy(alpha = 0.2f)
val Orange30 = Secondary.copy(alpha = 0.3f)

val Blue40 = Info
val Blue60 = Info
val Blue80 = Info.copy(alpha = 0.8f)
val Blue90 = Info.copy(alpha = 0.9f)
val Blue10 = Info.copy(alpha = 0.1f)
val Blue20 = Info.copy(alpha = 0.2f)
val Blue30 = Info.copy(alpha = 0.3f)

val Red40 = Error
val Red80 = Error.copy(alpha = 0.8f)
val Red90 = Error.copy(alpha = 0.9f)
val Red10 = Error.copy(alpha = 0.1f)
val Red20 = Error.copy(alpha = 0.2f)
val Red30 = Error.copy(alpha = 0.3f)

val Gray10 = TextPrimary
val Gray30 = TextSecondary
val Gray50 = TextSecondary
val Gray60 = TextSecondary
val Gray80 = TextTertiary
val Gray90 = TextTertiary
val Gray95 = BackgroundLight
val Gray99 = Color.White

// Status colors
val StatusOpen = Success
val StatusClosed = Error

// Delivery status colors
val DeliveryPending = StatusPending
val DeliveryPreparing = StatusPreparing
val DeliveryOnWay = StatusOnWay
val DeliveryDelivered = StatusDelivered
val DeliveryCancelled = StatusCancelled
