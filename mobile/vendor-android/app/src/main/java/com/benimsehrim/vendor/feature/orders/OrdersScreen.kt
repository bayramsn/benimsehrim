package com.benimsehrim.vendor.feature.orders

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrdersScreen(
    viewModel: OrdersViewModel = hiltViewModel(),
    onBack: () -> Unit,
    onOrderClick: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedFilter by remember { mutableStateOf("ALL") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Siparişler") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri")
                    }
                },
                actions = {
                    IconButton(onClick = { }) {
                        Icon(Icons.Default.FilterList, contentDescription = "Filtrele")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Filter Chips
            ScrollableTabRow(
                selectedTabIndex = listOf("ALL", "PENDING", "PREPARING", "READY", "ON_WAY").indexOf(selectedFilter),
                edgePadding = 16.dp
            ) {
                listOf(
                    "ALL" to "Tümü",
                    "PENDING" to "Bekleyen",
                    "PREPARING" to "Hazırlanan",
                    "READY" to "Hazır",
                    "ON_WAY" to "Yolda"
                ).forEach { (key, label) ->
                    Tab(
                        selected = selectedFilter == key,
                        onClick = {
                            selectedFilter = key
                            viewModel.filterOrders(key)
                        },
                        text = { Text(label) }
                    )
                }
            }

            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (uiState.orders.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Sipariş bulunamadı")
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(uiState.orders) { order ->
                        OrderCard(
                            order = order,
                            onClick = { onOrderClick(order.id) },
                            onAccept = { viewModel.acceptOrder(order.id) },
                            onStartPreparing = { viewModel.startPreparing(order.id) },
                            onMarkReady = { viewModel.markReady(order.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun OrderCard(
    order: VendorOrder,
    onClick: () -> Unit,
    onAccept: () -> Unit,
    onStartPreparing: () -> Unit,
    onMarkReady: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(order.orderNo, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(order.customerName, style = MaterialTheme.typography.bodyMedium)
                    Text(order.timeAgo, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("${order.total.toInt()}₺", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("${order.itemCount} ürün", style = MaterialTheme.typography.bodySmall)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action buttons based on status
            when (order.status) {
                "PENDING" -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = { },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)
                        ) {
                            Text("Reddet")
                        }
                        Button(
                            onClick = onAccept,
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                        ) {
                            Text("Onayla")
                        }
                    }
                }
                "ACCEPTED" -> {
                    Button(
                        onClick = onStartPreparing,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3))
                    ) {
                        Text("Hazırlamaya Başla")
                    }
                }
                "PREPARING" -> {
                    Button(
                        onClick = onMarkReady,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF009688))
                    ) {
                        Text("Hazır")
                    }
                }
                else -> {
                    // Status badge
                    val (color, text) = when (order.status) {
                        "READY" -> Color(0xFF26A69A) to "Kurye Bekleniyor"
                        "ON_WAY" -> Color(0xFFFF7043) to "Yolda"
                        "DELIVERED" -> Color(0xFF66BB6A) to "Teslim Edildi"
                        else -> Color.Gray to order.status
                    }
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        color = color.copy(alpha = 0.1f),
                        shape = MaterialTheme.shapes.small
                    ) {
                        Text(
                            text,
                            modifier = Modifier.padding(12.dp),
                            color = color,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        }
    }
}
