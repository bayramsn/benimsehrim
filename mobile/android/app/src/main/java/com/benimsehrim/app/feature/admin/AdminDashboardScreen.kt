package com.benimsehrim.app.feature.admin

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

fun AdminDashboardScreen(
    onNavigateBack: () -> Unit,
    viewModel: AdminViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = BackgroundDark,
        topBar = {
            TopAppBar(
                title = { Text("Yönetici Paneli", color = TextPrimary, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri", tint = TextPrimary)
                    }
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
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    StatCard(modifier = Modifier.weight(1f), title = "Aktif Üye", value = "${uiState.activeUsers}", color = Primary)
                    StatCard(modifier = Modifier.weight(1f), title = "Bugünkü Sipariş", value = "${uiState.dailyOrders}", color = Green40)
                }
            }

            item {
                Text("Kriz Monitörü (Silent Alarm)", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }

            item {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    // Dynamic Crisis Cards
                    if (uiState.crisisAlerts.isEmpty()) {
                        Text("Aktif kriz yok", color = TextSecondary, style = MaterialTheme.typography.bodySmall)
                    } else {
                        uiState.crisisAlerts.take(2).forEach { alert ->
                             CrisisCard(
                                modifier = Modifier.weight(1f),
                                title = alert.title,
                                count = alert.count,
                                color = if(alert.severity == "HIGH") Color.Red else Color(0xFFFF9800),
                                onClick = {}
                            )
                        }
                    }
                }
            }

             item {
                Text("Onay Bekleyenler", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }

            item {
                AdminActionCard(
                    title = "Mağaza Başvuruları",
                    subtitle = "3 Bekleyen Başvuru",
                    icon = Icons.Default.Store,
                    color = Primary,
                    onClick = { }
                )
            }
            
            item {
                AdminActionCard(
                    title = "Sürücü Başvuruları",
                    subtitle = "5 Bekleyen Başvuru",
                    icon = Icons.Default.LocalTaxi,
                    color = Color(0xFFFF9800),
                    onClick = { }
                )
            }
            
            item {
                AdminActionCard(
                    title = "Kurye Başvuruları",
                    subtitle = "2 Bekleyen Başvuru",
                    icon = Icons.Default.LocalShipping,
                    color = Color(0xFF9C27B0),
                    onClick = { }
                )
            }

            item {
                Text("Sistem Yönetimi", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }

            item {
                AdminActionCard(
                    title = "Kampanya Moderasyonu",
                    subtitle = "Aktif kampanyaları yönet",
                    icon = Icons.Default.Campaign,
                    color = Color(0xFFE91E63),
                    onClick = { }
                )
            }

            item {
                AdminActionCard(
                    title = "Kullanıcı Yönetimi",
                    subtitle = "Tüm kullanıcıları görüntüle",
                    icon = Icons.Default.People,
                    color = Color(0xFF2196F3),
                    onClick = { }
                )
            }
        }
    }
}

@Composable
fun StatsRow() {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        StatCard(modifier = Modifier.weight(1f), title = "Aktif Üye", value = "1,240", color = Primary)
        StatCard(modifier = Modifier.weight(1f), title = "Bugünkü Sipariş", value = "85", color = Green40)
    }
}

@Composable
fun StatCard(modifier: Modifier = Modifier, title: String, value: String, color: Color) {
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
fun AdminActionCard(
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

@Composable
fun CrisisCard(
    modifier: Modifier = Modifier,
    title: String,
    count: Int,
    color: Color,
    onClick: () -> Unit
) {
     Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(color.copy(alpha = 0.1f))
            .clickable(onClick = onClick)
            .padding(16.dp),
        horizontalAlignment = Alignment.Start
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
             Icon(Icons.Default.Warning, null, tint = color, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text(title, style = MaterialTheme.typography.bodySmall, color = color, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text("$count Alarm", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = TextPrimary)
    }
}
