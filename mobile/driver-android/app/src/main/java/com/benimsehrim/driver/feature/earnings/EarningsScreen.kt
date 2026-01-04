package com.benimsehrim.driver.feature.earnings

import androidx.compose.foundation.background
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

data class EarningEntry(
    val id: String,
    val type: String,
    val description: String,
    val amount: Double,
    val time: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EarningsScreen(onBack: () -> Unit) {
    val earnings = remember {
        listOf(
            EarningEntry("1", "TAXI", "Atatürk Mah. → Cumhuriyet Mah.", 45.0, "14:30"),
            EarningEntry("2", "TAXI", "Merkez → Terminal", 35.0, "13:15"),
            EarningEntry("3", "TAXI", "Hastane → Otogar", 28.0, "12:00"),
            EarningEntry("4", "TAXI", "Stadyum → AVM", 42.0, "10:45"),
            EarningEntry("5", "TAXI", "Belediye → Merkez", 22.0, "09:20"),
        )
    }

    val totalToday = earnings.sumOf { it.amount }
    val weeklyTotal = 2450.0
    val monthlyTotal = 8750.0

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Kazançlarım") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Summary Cards
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    EarningCard(
                        modifier = Modifier.weight(1f),
                        title = "Bugün",
                        amount = totalToday,
                        color = Color(0xFF4CAF50)
                    )
                    EarningCard(
                        modifier = Modifier.weight(1f),
                        title = "Bu Hafta",
                        amount = weeklyTotal,
                        color = Color(0xFF2196F3)
                    )
                    EarningCard(
                        modifier = Modifier.weight(1f),
                        title = "Bu Ay",
                        amount = monthlyTotal,
                        color = Color(0xFF9C27B0)
                    )
                }
            }

            // Stats
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        StatColumn("Toplam Yolculuk", "156")
                        StatColumn("Ortalama", "34₺")
                        StatColumn("Değerlendirme", "4.9⭐")
                    }
                }
            }

            // Today's Earnings Title
            item {
                Text(
                    "Bugünkü Kazançlar",
                    modifier = Modifier.padding(16.dp),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }

            // Earnings List
            items(earnings) { entry ->
                EarningItem(entry)
            }

            // Withdraw Button
            item {
                Button(
                    onClick = { },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .height(56.dp)
                ) {
                    Icon(Icons.Default.AccountBalance, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Para Çek")
                }
            }
        }
    }
}

@Composable
fun EarningCard(
    modifier: Modifier = Modifier,
    title: String,
    amount: Double,
    color: Color
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = color)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(title, color = Color.White.copy(alpha = 0.8f), style = MaterialTheme.typography.labelMedium)
            Text(
                "${amount.toInt()}₺",
                color = Color.White,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun StatColumn(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
    }
}

@Composable
fun EarningItem(entry: EarningEntry) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(Color(0xFFFFC107).copy(alpha = 0.2f), MaterialTheme.shapes.small),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.LocalTaxi, contentDescription = null, tint = Color(0xFFFFC107))
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(entry.description, style = MaterialTheme.typography.bodyMedium)
                Text(entry.time, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
            }
        }
        Text(
            "+${entry.amount.toInt()}₺",
            color = Color(0xFF4CAF50),
            fontWeight = FontWeight.Bold
        )
    }
    HorizontalDivider(modifier = Modifier.padding(start = 68.dp))
}
