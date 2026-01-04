package com.benimsehrim.vendor.feature.campaigns

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

data class Campaign(
    val id: String,
    val productName: String,
    val type: String, // PERCENTAGE, FIXED, BUY_GET
    val value: Int,
    val startDate: String,
    val endDate: String,
    val isActive: Boolean
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampaignsScreen(onBack: () -> Unit) {
    var showAddDialog by remember { mutableStateOf(false) }
    
    val campaigns = remember {
        listOf(
            Campaign("1", "Dana Kıyma", "PERCENTAGE", 20, "25 Ara", "31 Ara", true),
            Campaign("2", "Kuzu Pirzola", "FIXED", 50, "20 Ara", "27 Ara", false),
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Kampanyalar") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showAddDialog = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("Kampanya Oluştur") }
            )
        }
    ) { paddingValues ->
        if (campaigns.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Default.LocalOffer,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = Color.Gray
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Henüz kampanya yok", color = Color.Gray)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(campaigns) { campaign ->
                    CampaignCard(campaign = campaign)
                }
            }
        }
    }

    if (showAddDialog) {
        AddCampaignDialog(onDismiss = { showAddDialog = false })
    }
}

@Composable
fun CampaignCard(campaign: Campaign) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Campaign Icon
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = Color(0xFFFF5722).copy(alpha = 0.1f),
                modifier = Modifier.size(48.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        when (campaign.type) {
                            "PERCENTAGE" -> "%${campaign.value}"
                            "FIXED" -> "-${campaign.value}₺"
                            else -> "🎁"
                        },
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFFF5722)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(campaign.productName, fontWeight = FontWeight.Bold)
                Text(
                    "${campaign.startDate} - ${campaign.endDate}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }

            Switch(
                checked = campaign.isActive,
                onCheckedChange = { },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = Color(0xFF4CAF50)
                )
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddCampaignDialog(onDismiss: () -> Unit) {
    var selectedProduct by remember { mutableStateOf("") }
    var discountType by remember { mutableStateOf("PERCENTAGE") }
    var discountValue by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Yeni Kampanya") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                // Product selection
                var expanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = selectedProduct,
                        onValueChange = {},
                        label = { Text("Ürün Seç") },
                        readOnly = true,
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier.menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        listOf("Dana Kıyma", "Kuzu Pirzola", "Biftek").forEach { product ->
                            DropdownMenuItem(
                                text = { Text(product) },
                                onClick = {
                                    selectedProduct = product
                                    expanded = false
                                }
                            )
                        }
                    }
                }

                // Discount type
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = discountType == "PERCENTAGE",
                        onClick = { discountType = "PERCENTAGE" },
                        label = { Text("Yüzde") }
                    )
                    FilterChip(
                        selected = discountType == "FIXED",
                        onClick = { discountType = "FIXED" },
                        label = { Text("Sabit") }
                    )
                }

                // Discount value
                OutlinedTextField(
                    value = discountValue,
                    onValueChange = { discountValue = it.filter { c -> c.isDigit() } },
                    label = { Text(if (discountType == "PERCENTAGE") "İndirim (%)" else "İndirim (₺)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(onClick = { onDismiss() }) {
                Text("Oluştur")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("İptal")
            }
        }
    )
}
