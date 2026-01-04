package com.benimsehrim.app.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.benimsehrim.app.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    onNavigateToAddresses: () -> Unit,
    onNavigateToOrders: () -> Unit,
    onNavigateToWallet: () -> Unit,
    onNavigateToFavorites: () -> Unit,
    onNavigateToVendor: () -> Unit,
    onNavigateToCourier: () -> Unit,
    onNavigateToDriver: () -> Unit,
    onNavigateToAdmin: () -> Unit,
    onLogout: () -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = BackgroundDark,
        topBar = {
            TopAppBar(
                title = { 
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text(
                            "Profilim", 
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Geri", tint = TextPrimary)
                    }
                },
                actions = {
                    IconButton(onClick = { /* Settings */ }) {
                        Icon(Icons.Default.Settings, "Ayarlar", tint = Primary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            // Avatar Section
            Box {
                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(CircleShape)
                        .background(SurfaceDark),
                    contentAlignment = Alignment.Center
                ) {
                    AsyncImage(
                        model = "https://i.pravatar.cc/300?u=${uiState.name}",
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                }
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(Primary)
                        .padding(8.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.Edit, null, tint = TextOnPrimary, modifier = Modifier.size(20.dp))
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = uiState.name ?: "Kullanıcı Adı",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            Text(
                text = uiState.phone ?: "+90 555 123 45 67",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Action Grid 2x2
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ProfileActionCard(
                    modifier = Modifier.weight(1f),
                    title = "Cüzdanım",
                    value = "₺1.240.50",
                    icon = Icons.Default.AccountBalanceWallet,
                    iconBgColor = Primary,
                    onClick = onNavigateToWallet
                )
                ProfileActionCard(
                    modifier = Modifier.weight(1f),
                    title = "Siparişlerim",
                    value = "2 Aktif Sipariş",
                    icon = Icons.Default.ShoppingBag,
                    iconBgColor = Color(0xFFFF9800),
                    onClick = onNavigateToOrders
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ProfileActionCard(
                    modifier = Modifier.weight(1f),
                    title = "Favorilerim",
                    icon = Icons.Default.Favorite,
                    iconBgColor = Color(0xFFE91E63),
                    onClick = onNavigateToFavorites
                )
                ProfileActionCard(
                    modifier = Modifier.weight(1f),
                    title = "Adreslerim",
                    icon = Icons.Default.LocationOn,
                    iconBgColor = Color(0xFF2196F3),
                    onClick = onNavigateToAddresses
                )
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Section: Satıcı & Kurye
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    "Satıcı & Kurye",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(12.dp))
                ProfileListItem(
                    icon = Icons.Default.Store,
                    title = "Mağaza Aç / Yönet",
                    subtitle = "Satış yapmaya başla",
                    iconBgColor = Primary,
                    onClick = onNavigateToVendor
                )
                Spacer(modifier = Modifier.height(8.dp))
                
                if (uiState.isCourier) {
                    ProfileListItem(
                        icon = Icons.Default.LocalShipping,
                        title = "Kurye Paneli",
                        subtitle = "Teslimat yap",
                        iconBgColor = Color(0xFF9C27B0),
                        onClick = onNavigateToCourier
                    )
                } else {
                    ProfileListItem(
                        icon = Icons.Default.LocalShipping,
                        title = "Kurye Ol",
                        subtitle = "Kazanmaya başla",
                        iconBgColor = Color.Gray,
                        onClick = onNavigateToCourier
                    )
                }
                
                if (uiState.isDriver) {
                    Spacer(modifier = Modifier.height(8.dp))
                    ProfileListItem(
                        icon = Icons.Default.LocalTaxi,
                        title = "Sürücü Paneli",
                        subtitle = "Yolcu taşı",
                        iconBgColor = Color(0xFFFFC107),
                        onClick = onNavigateToDriver
                    )
                }

                if (uiState.role == "ADMIN") {
                    Spacer(modifier = Modifier.height(8.dp))
                    ProfileListItem(
                        icon = Icons.Default.AdminPanelSettings,
                        title = "Yönetici Paneli",
                        subtitle = "Sistem yönetimi",
                        iconBgColor = Color(0xFFF44336),
                        onClick = onNavigateToAdmin
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Section: Genel
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    "Genel",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(12.dp))
                ProfileListItem(
                    icon = Icons.Default.Language,
                    title = "Dil (Language)",
                    subtitle = "Türkçe",
                    onClick = { /* Change Language */ }
                )
                ProfileListItem(
                    icon = Icons.Default.HelpOutline,
                    title = "Yardım Merkezi",
                    onClick = { /* Help */ }
                )
                ProfileListItem(
                    icon = Icons.Default.Logout,
                    title = "Çıkış Yap",
                    titleColor = Error,
                    onClick = { viewModel.logout(); onLogout() }
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun ProfileActionCard(
    modifier: Modifier = Modifier,
    title: String,
    value: String? = null,
    icon: ImageVector,
    iconBgColor: Color,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .height(110.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(SurfaceDark)
            .clickable(onClick = onClick)
            .padding(16.dp)
    ) {
        Column {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(iconBgColor.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, null, tint = iconBgColor, modifier = Modifier.size(20.dp))
            }
            Spacer(modifier = Modifier.weight(1f))
            Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
            if (value != null) {
                Text(value, style = MaterialTheme.typography.labelSmall, color = iconBgColor, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun ProfileListItem(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    iconBgColor: Color? = null,
    titleColor: Color = TextPrimary,
    hasSwitch: Boolean = false,
    switchState: Boolean = false,
    onSwitchChange: ((Boolean) -> Unit)? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(SurfaceDark)
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (iconBgColor != null) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(iconBgColor.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, null, tint = iconBgColor, modifier = Modifier.size(20.dp))
            }
        } else {
            Icon(icon, null, tint = TextSecondary, modifier = Modifier.size(24.dp))
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, color = titleColor)
            if (subtitle != null) {
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
            }
        }
        
        if (hasSwitch) {
            Switch(
                checked = switchState,
                onCheckedChange = onSwitchChange,
                colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Primary)
            )
        } else if (titleColor != Error) {
            Icon(Icons.Default.ChevronRight, null, tint = TextSecondary, modifier = Modifier.size(20.dp))
        }
    }
}
