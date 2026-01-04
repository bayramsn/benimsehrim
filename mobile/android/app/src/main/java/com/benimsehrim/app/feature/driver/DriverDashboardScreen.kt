package com.benimsehrim.app.feature.driver

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
fun DriverDashboardScreen(
    onNavigateBack: () -> Unit,
    viewModel: DriverViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = BackgroundDark,
        topBar = {
            TopAppBar(
                title = { 
                    Column {
                        Text("Sürücü Paneli", color = TextPrimary, fontWeight = FontWeight.Bold)
                        Text(if(uiState.isOnline) "Çevrimiçi" else "Çevrimdışı", style = MaterialTheme.typography.labelSmall, color = if(uiState.isOnline) Green40 else Color.Gray)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri", tint = TextPrimary)
                    }
                },
                actions = {
                    Switch(
                        checked = uiState.isOnline,
                        onCheckedChange = { viewModel.toggleOnline(it) },
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
                // Operasyon Kartı
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(SurfaceDark)
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Yolcu Almaya Hazırım", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
                        Text(if(uiState.isReady) "Çağrı bekleniyor" else "Hazır değilsiniz", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                    // This switch is purely visual if isOnline handles everything? 
                    // Let's assume isOnline acts as master switch for now based on ViewModel logic
                    Switch(
                        checked = uiState.isReady,
                        onCheckedChange = { /* Ready is toggled via Online for now, or separate? Let's assume separate logic if needed but VM ties them */ },
                        enabled = false, // Controlled by Online Status
                        colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Green40)
                    )
                }
            }

            item {
                Row(
                   modifier = Modifier.fillMaxWidth(),
                   horizontalArrangement = Arrangement.spacedBy(8.dp) 
                ) {
                    Button(
                        onClick = { viewModel.toggleRestMode() },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = if(uiState.isInRestMode) Primary else SurfaceDark),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text(if(uiState.isInRestMode) "Molayı Bitir" else "30 Dk Mola", color = TextPrimary)
                    }
                    Button(
                        onClick = { /* Hedef Detay */ },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = SurfaceDark),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                         Text("Hedef: ${uiState.dailyRideCount}/${uiState.dailyGoalTotal} İş", color = Green40)
                    }
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
                    DriverStatCard(modifier = Modifier.weight(1f), title = "Kazanç", value = "₺${uiState.dailyEarnings.toInt()}", color = Green40)
                    DriverStatCard(modifier = Modifier.weight(1f), title = "Yolculuk", value = "${uiState.dailyRideCount}", color = Primary)
                }
            }
            
            item {
                Text("Çağrılar", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }
            
            if (uiState.isOnline) {
                // Mock waiting state
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(SurfaceDark),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            CircularProgressIndicator(color = Primary)
                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Yolcu aranıyor...", color = TextSecondary)
                        }
                    }
                }
            } else {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(SurfaceDark),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("Çağrı almak için çevrimiçi olun", color = TextSecondary)
                    }
                }
            }
            
             item {
                Text("Geçmiş", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
            }
            
            item {
                // Mock History Item
                 Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(SurfaceDark)
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text("Kırşehir Meydan -> Üniversite", style = MaterialTheme.typography.bodyMedium, color = TextPrimary, fontWeight = FontWeight.Bold)
                        Text("Dün, 14:30", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                    Text("₺120", style = MaterialTheme.typography.titleMedium, color = Green40, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun DriverStatCard(modifier: Modifier = Modifier, title: String, value: String, color: Color) {
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
