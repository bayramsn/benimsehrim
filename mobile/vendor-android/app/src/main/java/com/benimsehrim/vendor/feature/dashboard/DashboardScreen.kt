package com.benimsehrim.vendor.feature.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel = hiltViewModel(),
    onOrdersClick: () -> Unit,
    onProductsClick: () -> Unit,
    onCampaignsClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Mağazam", style = MaterialTheme.typography.titleLarge)
                        Text(
                            uiState.storeName,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                actions = {
                    // Store Open/Close Toggle
                    Switch(
                        checked = uiState.isOpen,
                        onCheckedChange = { viewModel.toggleStore(it) },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = Color(0xFF4CAF50)
                        )
                    )
                    IconButton(onClick = onSettingsClick) {
                        Icon(Icons.Default.Settings, contentDescription = "Ayarlar")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Earnings Chart
            item {
                EarningsGraphCard()
            }

            // Today Stats
            item {
                TodayStatsCard(
                    orderCount = uiState.todayOrders,
                    revenue = uiState.todayRevenue,
                    pendingOrders = uiState.pendingOrders
                )
            }
// ...
@Composable
fun RecentOrderCard(
    orderNo: String,
    customerName: String,
    total: Double,
    status: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
             modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(orderNo, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text(customerName, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("${total.toInt()}₺", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    StatusChip(status)
                }
            }
            
            if (status == "PENDING") {
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = { /* Accept logic */ },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                    ) {
                        Text("Kabul Et")
                    }
                    Button(
                        onClick = { /* Decline logic */ },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE53935))
                    ) {
                        Text("Reddet")
                    }
                }
            }
        }
    }
}

@Composable
fun EarningsGraphCard() {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Haftalık Gelir", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                                Color.Transparent
                            )
                        ),
                        shape = RoundedCornerShape(8.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                // Placeholder for real chart
                Canvas(modifier = Modifier.fillMaxSize().padding(8.dp)) {
                    val width = size.width
                    val height = size.height
                    
                    val path = androidx.compose.ui.graphics.Path().apply {
                        moveTo(0f, height * 0.8f)
                        cubicTo(
                            width * 0.3f, height * 0.9f,
                            width * 0.4f, height * 0.4f,
                            width * 0.6f, height * 0.5f
                        )
                        cubicTo(
                            width * 0.8f, height * 0.6f,
                            width * 0.9f, height * 0.2f,
                            width, height * 0.3f
                        )
                        lineTo(width, height)
                        lineTo(0f, height)
                        close()
                    }
                    
                    drawPath(
                        path = path,
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                Color(0xFF4CAF50),
                                Color.Transparent
                            )
                        )
                    )
                    
                    val linePath = androidx.compose.ui.graphics.Path().apply {
                        moveTo(0f, height * 0.8f)
                        cubicTo(
                            width * 0.3f, height * 0.9f,
                            width * 0.4f, height * 0.4f,
                            width * 0.6f, height * 0.5f
                        )
                        cubicTo(
                            width * 0.8f, height * 0.6f,
                            width * 0.9f, height * 0.2f,
                            width, height * 0.3f
                        )
                    }
                    
                    drawPath(
                        path = linePath,
                        color = Color(0xFF4CAF50),
                        style = androidx.compose.ui.graphics.drawscope.Stroke(
                            width = 4.dp.toPx()
                        )
                    )
                }
            }
        }
    }
}

            // Quick Actions
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    QuickActionCard(
                        modifier = Modifier.weight(1f),
                        icon = Icons.Default.ShoppingBag,
                        title = "Siparişler",
                        badge = if (uiState.pendingOrders > 0) uiState.pendingOrders.toString() else null,
                        onClick = onOrdersClick
                    )
                    QuickActionCard(
                        modifier = Modifier.weight(1f),
                        icon = Icons.Default.Inventory,
                        title = "Ürünler",
                        badge = null,
                        onClick = onProductsClick
                    )
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    QuickActionCard(
                        modifier = Modifier.weight(1f),
                        icon = Icons.Default.LocalOffer,
                        title = "Kampanyalar",
                        badge = null,
                        onClick = onCampaignsClick
                    )
                    QuickActionCard(
                        modifier = Modifier.weight(1f),
                        icon = Icons.Default.BarChart,
                        title = "İstatistikler",
                        badge = null,
                        onClick = { }
                    )
                }
            }

            // Recent Orders
            item {
                Text(
                    "Son Siparişler",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }

            if (uiState.recentOrders.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Henüz sipariş yok", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            } else {
                items(uiState.recentOrders) { order ->
                    RecentOrderCard(
                        orderNo = order.orderNo,
                        customerName = order.customerName,
                        total = order.total,
                        status = order.status,
                        onClick = { onOrdersClick() }
                    )
                }
            }
        }
    }
}

@Composable
fun TodayStatsCard(
    orderCount: Int,
    revenue: Double,
    pendingOrders: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF006E24))
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                "Bugün",
                style = MaterialTheme.typography.titleMedium,
                color = Color.White.copy(alpha = 0.8f)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                StatItem(label = "Sipariş", value = orderCount.toString(), color = Color.White)
                StatItem(label = "Gelir", value = "${revenue.toInt()}₺", color = Color.White)
                StatItem(label = "Bekleyen", value = pendingOrders.toString(), color = Color(0xFFFFB74D))
            }
        }
    }
}

@Composable
fun StatItem(label: String, value: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            value,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = color
        )
        Text(
            label,
            style = MaterialTheme.typography.bodySmall,
            color = color.copy(alpha = 0.7f)
        )
    }
}

@Composable
fun QuickActionCard(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    title: String,
    badge: String?,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier.clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Box(modifier = Modifier.padding(16.dp)) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    icon,
                    contentDescription = title,
                    modifier = Modifier.size(32.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(title, style = MaterialTheme.typography.bodyMedium)
            }
            if (badge != null) {
                Badge(
                    modifier = Modifier.align(Alignment.TopEnd),
                    containerColor = Color.Red
                ) {
                    Text(badge)
                }
            }
        }
    }
}

@Composable
fun RecentOrderCard(
    orderNo: String,
    customerName: String,
    total: Double,
    status: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
             modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(orderNo, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text(customerName, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("${total.toInt()}₺", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    StatusChip(status)
                }
            }
            
            if (status == "PENDING") {
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = { /* Accept logic */ },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                    ) {
                        Text("Kabul Et")
                    }
                    Button(
                        onClick = { /* Decline logic */ },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE53935))
                    ) {
                        Text("Reddet")
                    }
                }
            }
        }
    }
}

@Composable
fun StatusChip(status: String) {
    val (color, text) = when (status) {
        "PENDING" -> Color(0xFFFFA726) to "Bekliyor"
        "ACCEPTED" -> Color(0xFF42A5F5) to "Onaylandı"
        "PREPARING" -> Color(0xFF7E57C2) to "Hazırlanıyor"
        "READY" -> Color(0xFF26A69A) to "Hazır"
        "ON_WAY" -> Color(0xFFFF7043) to "Yolda"
        "DELIVERED" -> Color(0xFF66BB6A) to "Teslim"
        else -> Color.Gray to status
    }

    Surface(
        shape = RoundedCornerShape(4.dp),
        color = color.copy(alpha = 0.2f)
    ) {
        Text(
            text,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
            style = MaterialTheme.typography.labelSmall,
            color = color
        )
    }
}
