package com.benimsehrim.app.feature.vendor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.benimsehrim.app.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorDashboardScreen(
    onNavigateBack: () -> Unit,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = BackgroundDark,
        topBar = {
            TopAppBar(
                title = { 
                    Column {
                        Text("Mağaza Paneli", color = TextPrimary, fontWeight = FontWeight.Bold)
                        Text(if(uiState.isStoreOpen) "Mağaza Açık" else "Mağaza Kapalı", style = MaterialTheme.typography.labelSmall, color = if(uiState.isStoreOpen) Green40 else Color.Red)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri", tint = TextPrimary)
                    }
                },
                actions = {
                    Switch(
                        checked = uiState.isStoreOpen,
                        onCheckedChange = { viewModel.toggleStoreOpen(it) },
                        colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Green40)
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BackgroundDark)
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Text("Operasyon", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }

            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(SurfaceDark)
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Sipariş Almaya Hazırım", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
                        Text(if(uiState.isReady) "Sipariş kabul ediliyor" else "Şu an sipariş almıyorsunuz", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                    Switch(
                        checked = uiState.isReady,
                        onCheckedChange = { viewModel.toggleReady(it) },
                        colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Green40)
                    )
                }
            }
            
            item {
                Text("Günlük Özet", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }
            
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    VendorStatCard(modifier = Modifier.weight(1f), title = "Ciro", value = "₺${uiState.dailyRevenue.toInt()}", color = Green40)
                    VendorStatCard(modifier = Modifier.weight(1f), title = "Sipariş", value = "${uiState.dailyOrders}", color = Primary)
                }
            }

            item {
                Text("Yönetim", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }

            item {
                VendorActionCard(
                    title = "Ürün Yönetimi",
                    subtitle = "Ürün ekle, düzenle, stok güncelle",
                    icon = Icons.Default.Inventory,
                    color = Color(0xFFFF9800),
                    onClick = { }
                )
            }
            
            item {
                VendorActionCard(
                    title = "Siparişler",
                    subtitle = "Gelen ve tamamlanan siparişler",
                    icon = Icons.Default.ReceiptLong,
                    color = Color(0xFF2196F3),
                    onClick = { }
                )
            }
            
            item {
                VendorActionCard(
                    title = "Kampanyalar",
                    subtitle = "İndirim ve fırsatlar oluştur",
                    icon = Icons.Default.LocalOffer,
                    color = Color(0xFFE91E63),
                    onClick = { }
                )
            }
            
            item {
                VendorActionCard(
                    title = "Ayarlar",
                    subtitle = "Mağaza bilgileri, çalışma saatleri",
                    icon = Icons.Default.Settings,
                    color = TextSecondary,
                    onClick = { }
                )
            }
        }
    }
}

@Composable
fun VendorStatCard(modifier: Modifier = Modifier, title: String, value: String, color: Color) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceDark)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(value, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = color)
        Text(title, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
    }
}

@Composable
fun VendorActionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    color: Color,
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
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(color.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = color, modifier = Modifier.size(24.dp))
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
        }
        Icon(Icons.Default.ChevronRight, null, tint = TextSecondary)
    }
}
