# 🎨 UI/UX Design System

## Renk Paleti

### Primary Colors

```
Primary: #6366F1 (Indigo)
Primary Variant: #4F46E5
Primary Light: #818CF8
Primary Dark: #3730A3
```

### Secondary Colors

```
Secondary: #F59E0B (Amber)
Secondary Variant: #D97706
Secondary Light: #FBBF24
```

### Status Colors

```
Success: #10B981 (Emerald)
Warning: #F59E0B (Amber)
Error: #EF4444 (Red)
Info: #3B82F6 (Blue)
```

### Background & Surface

```
Background Light: #F9FAFB
Background Dark: #111827
Surface Light: #FFFFFF
Surface Dark: #1F2937
```

### Text Colors

```
Text Primary: #111827
Text Secondary: #6B7280
Text Tertiary: #9CA3AF
Text On Primary: #FFFFFF
```

## Typography

### Font Family

- **Primary**: Inter (Google Fonts)
- **Fallback**: System Default

### Font Sizes

```
Display Large: 57sp / 57pt
Display Medium: 45sp / 45pt
Display Small: 36sp / 36pt

Headline Large: 32sp / 32pt
Headline Medium: 28sp / 28pt
Headline Small: 24sp / 24pt

Title Large: 22sp / 22pt
Title Medium: 16sp / 16pt
Title Small: 14sp / 14pt

Body Large: 16sp / 16pt
Body Medium: 14sp / 14pt
Body Small: 12sp / 12pt

Label Large: 14sp / 14pt
Label Medium: 12sp / 12pt
Label Small: 11sp / 11pt
```

### Font Weights

```
Regular: 400
Medium: 500
SemiBold: 600
Bold: 700
```

## Spacing System

### Base Unit: 4dp/pt

```
XXS: 4dp/pt
XS: 8dp/pt
S: 12dp/pt
M: 16dp/pt
L: 24dp/pt
XL: 32dp/pt
XXL: 48dp/pt
```

## Border Radius

```
Small: 8dp/pt
Medium: 12dp/pt
Large: 16dp/pt
XLarge: 20dp/pt
Round: 999dp/pt
```

## Elevation & Shadows

### Android

```
Level 1: 2dp elevation
Level 2: 4dp elevation
Level 3: 8dp elevation
Level 4: 12dp elevation
Level 5: 16dp elevation
```

### iOS

```
Level 1: shadow(radius: 2, y: 1)
Level 2: shadow(radius: 4, y: 2)
Level 3: shadow(radius: 8, y: 4)
Level 4: shadow(radius: 12, y: 6)
Level 5: shadow(radius: 16, y: 8)
```

## Components

### 1. Buttons

#### Primary Button (Gradient)

```kotlin
// Android
GradientButton(
    text = "Devam Et",
    onClick = { },
    enabled = true,
    loading = false
)
```

```swift
// iOS
Button("Devam Et") { }
    .buttonStyle(GradientButtonStyle())
```

**Specs**:

- Height: 56dp/pt
- Corner Radius: 16dp/pt
- Gradient: Primary → Secondary
- Shadow: 8dp/pt elevation
- Font: Title Medium, SemiBold

#### Secondary Button

```kotlin
// Android
OutlinedButton(
    onClick = { },
    modifier = Modifier
        .fillMaxWidth()
        .height(56.dp),
    shape = RoundedCornerShape(16.dp),
    border = BorderStroke(2.dp, Primary)
) {
    Text("İptal")
}
```

**Specs**:

- Height: 56dp/pt
- Border: 2dp/pt, Primary color
- Corner Radius: 16dp/pt
- No shadow

### 2. Cards

#### Modern Card

```kotlin
// Android
ModernCard(
    elevation = 2,
    onClick = { }
) {
    // Content
}
```

```swift
// iOS
ModernCard(elevation: 2) {
    // Content
}
```

**Specs**:

- Padding: 16dp/pt
- Corner Radius: 20dp/pt
- Background: Surface Light
- Shadow: Level 2

### 3. Status Badges

```kotlin
// Android
StatusBadge(status = "PENDING")
```

```swift
// iOS
StatusBadge(status: "PENDING")
```

**Specs**:

- Padding: 6dp/pt vertical, 12dp/pt horizontal
- Corner Radius: 8dp/pt
- Font: Label Small, Medium
- Background: Status color with 15% opacity

### 4. Input Fields

```kotlin
// Android
OutlinedTextField(
    value = text,
    onValueChange = { text = it },
    modifier = Modifier.fillMaxWidth(),
    shape = RoundedCornerShape(12.dp),
    colors = OutlinedTextFieldDefaults.colors(
        focusedBorderColor = Primary,
        unfocusedBorderColor = Border
    )
)
```

**Specs**:

- Height: 56dp/pt
- Corner Radius: 12dp/pt
- Border: 1dp/pt
- Padding: 16dp/pt horizontal

### 5. Loading States

#### Shimmer Effect

```kotlin
// Android
ShimmerEffect(
    modifier = Modifier
        .fillMaxWidth()
        .height(100.dp)
        .clip(RoundedCornerShape(12.dp))
)
```

```swift
// iOS
ShimmerView()
    .frame(height: 100)
    .cornerRadius(12)
```

### 6. Empty States

```kotlin
// Android
EmptyStateView(
    title = "Sipariş Yok",
    description = "Henüz hiç sipariş vermediniz",
    icon = { Icon(Icons.Default.ShoppingBag, null) },
    actionText = "Alışverişe Başla",
    onActionClick = { }
)
```

```swift
// iOS
EmptyStateView(
    title: "Sipariş Yok",
    description: "Henüz hiç sipariş vermediniz",
    icon: Image(systemName: "bag"),
    actionText: "Alışverişe Başla",
    action: { }
)
```

## Design Principles

### 1. Consistency

- Aynı component'ler her yerde aynı şekilde görünmeli
- Spacing sistemi tutarlı kullanılmalı
- Color palette'ten sapılmamalı

### 2. Hierarchy

- Başlıklar bold/semibold olmalı
- Primary actions gradient button olmalı
- Secondary actions outlined button olmalı

### 3. Feedback

- Button press animasyonları olmalı
- Loading states gösterilmeli
- Success/Error feedback verilmeli

### 4. Accessibility

- Minimum touch target: 48dp/pt
- Contrast ratio: 4.5:1 (text)
- Font size: Minimum 12sp/pt

### 5. Performance

- Image lazy loading
- List virtualization
- Shimmer loading states

## Animation Guidelines

### Duration

```
Fast: 150ms
Normal: 300ms
Slow: 500ms
```

### Easing

```
Standard: cubic-bezier(0.4, 0.0, 0.2, 1)
Decelerate: cubic-bezier(0.0, 0.0, 0.2, 1)
Accelerate: cubic-bezier(0.4, 0.0, 1, 1)
```

### Common Animations

```
Button Press: Scale 0.98, Duration 150ms
Card Appear: Fade + Slide, Duration 300ms
Page Transition: Slide, Duration 300ms
Loading: Shimmer, Duration 1200ms
```

## Iconography

### Icon Set

- **Android**: Material Icons
- **iOS**: SF Symbols

### Icon Sizes

```
Small: 16dp/pt
Medium: 24dp/pt
Large: 32dp/pt
XLarge: 48dp/pt
```

### Icon Colors

```
Primary: Text Primary
Secondary: Text Secondary
Accent: Primary Color
Disabled: Text Tertiary
```

## Layout Guidelines

### Screen Padding

```
Mobile: 16dp/pt
Tablet: 24dp/pt
```

### Content Max Width

```
Mobile: Full width
Tablet: 600dp/pt
```

### Grid System

```
Columns: 12
Gutter: 16dp/pt
Margin: 16dp/pt
```

## Best Practices

### DO ✅

- Use gradient buttons for primary actions
- Show loading states during async operations
- Use status badges for order states
- Implement shimmer loading
- Add micro-animations
- Use modern card designs
- Follow spacing system
- Use semantic colors

### DON'T ❌

- Don't use flat colors for primary buttons
- Don't skip loading states
- Don't use inconsistent spacing
- Don't ignore accessibility
- Don't use too many colors
- Don't skip animations
- Don't use small touch targets
- Don't ignore empty states

## Component Library

### Android

- `ModernComponents.kt` - Reusable components
- `Color.kt` - Color system
- `Type.kt` - Typography system

### iOS

- `ModernComponents.swift` - Reusable components
- `Colors.swift` - Color system
- Built-in SwiftUI typography

## Examples

### Store Card

```kotlin
ModernCard(elevation = 2) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(
                "Kasap Ahmet",
                style = MaterialTheme.typography.titleMedium
            )
            RatingStars(rating = 4.5)
        }
        StatusBadge(status = "OPEN")
    }
}
```

### Order Item

```kotlin
ModernCard(elevation = 1) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                "Sipariş #1234",
                style = MaterialTheme.typography.titleSmall
            )
            Text(
                "2 ürün • 150₺",
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary
            )
        }
        StatusBadge(status = "DELIVERING")
    }
}
```

## Resources

### Fonts

- [Inter Font](https://fonts.google.com/specimen/Inter)

### Icons

- [Material Icons](https://fonts.google.com/icons)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

### Design Tools

- Figma
- Adobe XD
- Sketch

### Inspiration

- [Material Design 3](https://m3.material.io/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Dribbble](https://dribbble.com/)
