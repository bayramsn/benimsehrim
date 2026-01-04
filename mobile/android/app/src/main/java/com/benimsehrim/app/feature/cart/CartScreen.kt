package com.benimsehrim.app.feature.cart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.benimsehrim.app.core.model.Product
import com.benimsehrim.app.ui.theme.*
import androidx.compose.foundation.clickable

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CartScreen(
    onNavigateToCheckout: () -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: CartViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = BackgroundDark,
        topBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BackgroundDark)
                    .padding(top = 16.dp, start = 8.dp, end = 16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Geri", tint = TextPrimary)
                    }
                    Text(
                        "Sepetim",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    if (uiState.itemCount > 0) {
                        TextButton(onClick = { viewModel.clearCart() }) {
                            Text("Sepeti Boşalt", color = Error, style = MaterialTheme.typography.labelMedium)
                        }
                    }
                }
                
                // Address Selector
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(SurfaceDark)
                        .clickable { /* Change address */ }
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.LocationOn, null, tint = Primary, modifier = Modifier.size(20.dp))
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Teslimat Adresi", style = MaterialTheme.typography.labelSmall, color = TextSecondary)
                        Text("Evim (Kemalpaşa Mah...)", style = MaterialTheme.typography.bodySmall, color = TextPrimary, fontWeight = FontWeight.Bold)
                    }
                    Icon(Icons.Default.ChevronRight, null, tint = TextSecondary, modifier = Modifier.size(20.dp))
                }
            }
        },
        bottomBar = {
            if (uiState.itemCount > 0) {
                Surface(
                    color = SurfaceDark,
                    shape = RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp),
                    shadowElevation = 16.dp
                ) {
                    Column(modifier = Modifier.padding(24.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Toplam", style = MaterialTheme.typography.titleMedium, color = TextPrimary, fontWeight = FontWeight.Bold)
                            Text("${uiState.totalAmount.toInt() + 15}₺", style = MaterialTheme.typography.headlineSmall, color = Primary, fontWeight = FontWeight.Bold)
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(
                            onClick = onNavigateToCheckout,
                            modifier = Modifier.fillMaxWidth().height(56.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Primary)
                        ) {
                            Text("Siparişi Onayla", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextOnPrimary)
                        }
                    }
                }
            }
        }
    ) { padding ->
        if (uiState.itemCount == 0) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.ShoppingCart, null, modifier = Modifier.size(100.dp), tint = SurfaceDark)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Sepetin şu an boş", style = MaterialTheme.typography.titleLarge, color = TextPrimary, fontWeight = FontWeight.Bold)
                    Text("Lezzetli ürünleri keşfetmeye başla!", style = MaterialTheme.typography.bodyMedium, color = TextSecondary)
                    Spacer(modifier = Modifier.height(32.dp))
                    Button(onClick = onNavigateBack, colors = ButtonDefaults.buttonColors(containerColor = Primary)) {
                        Text("Alışverişe Başla", color = TextOnPrimary)
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(uiState.items.toList()) { (product, quantity) ->
                    CartItemRow(
                        product = product,
                        quantity = quantity,
                        onIncrease = { viewModel.increaseQuantity(product) },
                        onDecrease = { viewModel.decreaseQuantity(product) }
                    )
                }
                
                // Promo Code
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(16.dp))
                            .background(SurfaceDark)
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.LocalOffer, null, tint = Primary, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(12.dp))
                        Text("İndirim Kodu Ekle", style = MaterialTheme.typography.bodyMedium, color = TextPrimary, modifier = Modifier.weight(1f))
                        Icon(Icons.Default.Add, null, tint = Primary)
                    }
                }
                
                // Summary
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(16.dp))
                            .background(SurfaceDark)
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        SummaryRow("Sipariş Tutarı", "${uiState.totalAmount.toInt()}₺")
                        SummaryRow("Teslimat Ücreti", "15₺")
                        SummaryRow("İndirim", "-0₺", color = Primary)
                    }
                }
                
                item { Spacer(modifier = Modifier.height(80.dp)) }
            }
        }
    }
}

@Composable
fun SummaryRow(label: String, value: String, color: Color = TextSecondary) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = TextSecondary)
        Text(value, style = MaterialTheme.typography.bodyMedium, color = if (color == Primary) color else TextPrimary, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun CartItemRow(
    product: Product,
    quantity: Int,
    onIncrease: () -> Unit,
    onDecrease: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(SurfaceDark)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AsyncImage(
            model = product.images.firstOrNull(),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(80.dp).clip(RoundedCornerShape(12.dp))
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(product.name, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = TextPrimary)
            Text(product.description ?: "", style = MaterialTheme.typography.labelSmall, color = TextSecondary, maxLines = 1)
            Spacer(modifier = Modifier.height(8.dp))
            Text("${product.price.toInt()}₺", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Primary)
        }
        
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            IconButton(
                onClick = onIncrease,
                modifier = Modifier.size(28.dp).clip(CircleShape).background(Primary)
            ) {
                Icon(Icons.Default.Add, null, modifier = Modifier.size(16.dp), tint = TextOnPrimary)
            }
            Text(quantity.toString(), modifier = Modifier.padding(vertical = 4.dp), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
            IconButton(
                onClick = onDecrease,
                modifier = Modifier.size(28.dp).clip(CircleShape).background(BackgroundDark)
            ) {
                Icon(Icons.Default.Remove, null, modifier = Modifier.size(16.dp), tint = TextPrimary)
            }
        }
    }
}
