package com.benimsehrim.app.feature.checkout

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import com.benimsehrim.app.core.model.Address
import com.benimsehrim.app.ui.theme.Green40

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckoutScreen(
    onNavigateBack: () -> Unit,
    onOrderSuccess: () -> Unit,
    viewModel: CheckoutViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState.isOrderCreated) {
        if (uiState.isOrderCreated) {
            onOrderSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Siparişi Tamamla", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Geri")
                    }
                }
            )
        },
        bottomBar = {
            Button(
                onClick = { viewModel.completeOrder() },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
                    .height(56.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Green40),
                enabled = !uiState.isLoading
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(color = Color.White)
                } else {
                    Text("Siparişi Onayla (${(uiState.totalAmount - uiState.discountAmount).toInt()}₺)", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .background(Color(0xFFF5F5F5)),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Address Section
            item {
                Text("Teslimat Adresi", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(uiState.addresses) { address ->
                        AddressCard(
                            address = address,
                            isSelected = address.id == uiState.selectedAddress?.id,
                            onSelect = { viewModel.selectAddress(address) }
                        )
                    }
                    item {
                        AddAddressCard()
                    }
                }
            }

            // Payment Method
            item {
                Text("Ödeme Yöntemi", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White)
                ) {
                    PaymentOptionRow(
                        title = "Nakit",
                        icon = Icons.Default.Money,
                        selected = uiState.paymentMethod == "Nakit",
                        onSelect = { viewModel.selectPaymentMethod("Nakit") }
                    )
                    Divider()
                    PaymentOptionRow(
                        title = "Kredi Kartı (Kapıda)",
                        icon = Icons.Default.CreditCard,
                        selected = uiState.paymentMethod == "Kredi Kartı",
                        onSelect = { viewModel.selectPaymentMethod("Kredi Kartı") }
                    )
                }
            }

            // Note
            item {
                Text("Sipariş Notu", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = uiState.note,
                    onValueChange = { viewModel.updateNote(it) },
                    placeholder = { Text("Zil çalışmıyor, kapıya bırakın vb.") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White, RoundedCornerShape(12.dp)),
                    shape = RoundedCornerShape(12.dp)
                )
            }
            
            // Coupon Section
            item {
                Text("İndirim Kuponu", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                 Spacer(modifier = Modifier.height(8.dp))
                 Row(verticalAlignment = Alignment.CenterVertically) {
                     OutlinedTextField(
                         value = uiState.couponCode,
                         onValueChange = { viewModel.onCouponCodeChanged(it) },
                         placeholder = { Text("Kupon kodu") },
                         modifier = Modifier
                             .weight(1f)
                             .background(Color.White, RoundedCornerShape(12.dp)),
                         shape = RoundedCornerShape(12.dp),
                         singleLine = true,
                         enabled = !uiState.isCouponApplied
                     )
                     Spacer(modifier = Modifier.width(8.dp))
                     if (uiState.isCouponApplied) {
                         Button(
                             onClick = { viewModel.removeCoupon() },
                             colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                             shape = RoundedCornerShape(12.dp),
                             contentPadding = PaddingValues(horizontal = 16.dp)
                         ) {
                             Text("Kaldır")
                         }
                     } else {
                        Button(
                             onClick = { viewModel.applyCoupon() },
                             colors = ButtonDefaults.buttonColors(containerColor = Green40),
                             shape = RoundedCornerShape(12.dp),
                             contentPadding = PaddingValues(horizontal = 16.dp),
                             enabled = uiState.couponCode.isNotEmpty()
                         ) {
                             Text("Uygula")
                         }
                     }
                 }
                 if (uiState.couponMessage != null) {
                     Text(
                         text = uiState.couponMessage!!,
                         style = MaterialTheme.typography.bodySmall,
                         color = if (uiState.isCouponApplied) Green40 else MaterialTheme.colorScheme.error,
                         modifier = Modifier.padding(start = 4.dp, top = 4.dp)
                     )
                 }
            }

            // Summary
            item {
                Text("Özet", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                Card(
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Ara Toplam")
                            Text("${uiState.totalAmount.toInt()}₺")
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        if (uiState.discountAmount > 0) {
                             Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("İndirim")
                                Text("-${uiState.discountAmount.toInt()}₺", color = Green40)
                            }
                             Spacer(modifier = Modifier.height(8.dp))
                        }
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Teslimat Ücreti")
                            Text("Ücretsiz", color = Green40)
                        }
                        Divider(modifier = Modifier.padding(vertical = 12.dp))
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Toplam", fontWeight = FontWeight.Bold)
                            Text("${(uiState.totalAmount - uiState.discountAmount).toInt()}₺", fontWeight = FontWeight.Bold, color = Green40, style = MaterialTheme.typography.titleLarge)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AddressCard(address: Address, isSelected: Boolean, onSelect: () -> Unit) {
    Card(
        modifier = Modifier
            .width(200.dp)
            .height(140.dp)
            .clickable(onClick = onSelect)
            .border(
                width = if (isSelected) 2.dp else 0.dp,
                color = if (isSelected) Green40 else Color.Transparent,
                shape = RoundedCornerShape(12.dp)
            ),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = if (isSelected) Green40.copy(alpha = 0.05f) else Color.White)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    if (address.title == "Ev") Icons.Default.Home else Icons.Default.Work,
                    contentDescription = null,
                    tint = if (isSelected) Green40 else Color.Gray,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(address.title, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.weight(1f))
                if (isSelected) {
                    Icon(Icons.Default.CheckCircle, null, tint = Green40, modifier = Modifier.size(20.dp))
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(address.address, style = MaterialTheme.typography.bodySmall, color = Color.Gray, maxLines = 3)
        }
    }
}

@Composable
fun AddAddressCard() {
    Card(
        modifier = Modifier
            .width(120.dp)
            .height(140.dp)
            .clickable { /* Navigate to Add Address */ },
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(Icons.Default.Add, null, tint = Green40)
            Spacer(modifier = Modifier.height(8.dp))
            Text("Adres Ekle", style = MaterialTheme.typography.labelMedium)
        }
    }
}

@Composable
fun PaymentOptionRow(title: String, icon: ImageVector, selected: Boolean, onSelect: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onSelect)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, tint = if (selected) Green40 else Color.Gray)
        Spacer(modifier = Modifier.width(16.dp))
        Text(title, modifier = Modifier.weight(1f))
        RadioButton(selected = selected, onClick = onSelect, colors = RadioButtonDefaults.colors(selectedColor = Green40))
    }
}
