package com.benimsehrim.vendor.feature.orders

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderDetailScreen(
    orderId: String,
    onBack: () -> Unit
) {
    // Demo order
    val order = VendorOrder(
        id = orderId,
        orderNo = "ORD-2024-001",
        customerName = "Ahmet Yılmaz",
        customerPhone = "+905001234567",
        total = 245.0,
        itemCount = 3,
        status = "PREPARING",
        timeAgo = "15 dk önce",
        items = listOf(
            OrderItem("Dana Kıyma (1kg)", 2, 280.0),
            OrderItem("Kuzu Pirzola (500g)", 1, 160.0),
            OrderItem("Sucuk (300g)", 1, 45.0)
        )
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(order.orderNo) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri")
                    }
                },
                actions = {
                    IconButton(onClick = { /* Print */ }) {
                        Icon(Icons.Default.Print, contentDescription = "Yazdır")
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
            // Customer Info
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Person, contentDescription = null, tint = Color.Gray)
                            Spacer(modifier = Modifier.width(8.dp))
                            Column {
                                Text(order.customerName, fontWeight = FontWeight.Bold)
                                Text(order.customerPhone, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                            }
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.LocationOn, contentDescription = null, tint = Color.Gray)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Atatürk Mah. 123 Sok. No:5", style = MaterialTheme.typography.bodyMedium)
                        }
                        if (order.status == "READY" || order.status == "ON_WAY") {
                            Spacer(modifier = Modifier.height(12.dp))
                            Button(
                                onClick = { /* Call customer */ },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Icon(Icons.Default.Phone, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Müşteriyi Ara")
                            }
                        }
                    }
                }
            }

            // Order Items
            item {
                Text("Sipariş Detayı", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            }

            items(order.items) { item ->
                Card(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(item.name, fontWeight = FontWeight.Medium)
                            Text("${item.quantity} adet", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                        }
                        Text("${(item.price * item.quantity).toInt()}₺", fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Total
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Toplam", style = MaterialTheme.typography.titleMedium)
                        Text("${order.total.toInt()}₺", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Note
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Müşteri Notu", fontWeight = FontWeight.Medium)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Kıyma orta yağlı olsun lütfen.", color = Color.Gray)
                    }
                }
            }

            // Actions
            item {
                when (order.status) {
                    "PENDING" -> {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            OutlinedButton(
                                onClick = { },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)
                            ) {
                                Text("Reddet")
                            }
                            Button(
                                onClick = { },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
                            ) {
                                Text("Onayla")
                            }
                        }
                    }
                    "ACCEPTED" -> {
                        Button(
                            onClick = { },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3))
                        ) {
                            Text("Hazırlamaya Başla")
                        }
                    }
                    "PREPARING" -> {
                        Button(
                            onClick = { },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF009688))
                        ) {
                            Text("Sipariş Hazır")
                        }
                    }
                }
            }
        }
    }
}
