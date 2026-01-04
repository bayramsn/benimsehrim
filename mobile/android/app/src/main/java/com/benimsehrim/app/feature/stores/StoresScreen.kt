package com.benimsehrim.app.feature.stores

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.benimsehrim.app.core.model.Store
import com.benimsehrim.app.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StoresScreen(
    categoryId: String?,
    onNavigateToStore: (String) -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: StoresViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedFilter by remember { mutableStateOf("Tümü") }

    LaunchedEffect(categoryId) {
        viewModel.loadStores(categoryId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mağazalar") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Geri")
                    }
                }
            )
        },
        containerColor = MaterialTheme.colorScheme.surfaceVariant
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Filter Chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val filters = listOf("Tümü", "Açık", "Restoran", "Market", "Puan 4.5+", "Ücretsiz Teslimat")
                items(filters) { filter ->
                    FilterChip(
                        selected = selectedFilter == filter,
                        onClick = { selectedFilter = filter },
                        label = { Text(filter) },
                        leadingIcon = if (selectedFilter == filter) {
                            { Icon(Icons.Default.Check, contentDescription = null) }
                        } else null,
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = Green40.copy(alpha = 0.2f),
                            selectedLabelColor = Green40,
                            selectedLeadingIconColor = Green40
                        )
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
            } else {
                val filteredStores = uiState.stores.filter { store ->
                    when (selectedFilter) {
                        "Açık" -> store.isOpen
                        "Puan 4.5+" -> store.rating >= 4.5
                        "Ücretsiz Teslimat" -> store.deliveryFee == 0.0
                        "Restoran" -> store.name.contains("Restoran") || store.name.contains("Döner") || store.name.contains("Pizza")
                        "Market" -> store.name.contains("Market") || store.name.contains("Bakkal")
                        else -> true
                    }
                }

                if (filteredStores.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("🏪", style = MaterialTheme.typography.displayLarge)
                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Bu filtreye uygun mağaza bulunamadı")
                        }
                    }
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(bottom = 16.dp)
                    ) {
                        items(filteredStores) { store ->
                            StoreListItem(
                                store = store,
                                onClick = { onNavigateToStore(store.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StoreListItem(
    store: Store,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column {
            // Banner Image
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(150.dp)
                    .background(MaterialTheme.colorScheme.surfaceVariant)
            ) {
                 AsyncImage(
                    model = store.bannerUrl ?: "https://picsum.photos/seed/${store.id}/600/300", 
                    contentDescription = store.name,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
                
                // Status Badge
                Surface(
                    modifier = Modifier
                        .padding(12.dp)
                        .align(Alignment.TopEnd),
                    shape = RoundedCornerShape(8.dp),
                    color = if (store.isOpen) Green40 else MaterialTheme.colorScheme.error
                ) {
                    Text(
                        text = if (store.isOpen) "Açık" else "Kapalı",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )
                }

                // Delivery Time (On Image)
                if (store.deliveryTime != null) {
                    Surface(
                         modifier = Modifier
                            .padding(12.dp)
                            .align(Alignment.BottomStart),
                        shape = RoundedCornerShape(8.dp),
                        color = MaterialTheme.colorScheme.surface
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                             Icon(
                                Icons.Default.AccessTime,
                                contentDescription = null,
                                modifier = Modifier.size(12.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = store.deliveryTime!!,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
            
            // Info Content
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                 // Circular Logo
                 Surface(
                    shape = CircleShape,
                    shadowElevation = 2.dp,
                    modifier = Modifier.size(40.dp)
                ) {
                    AsyncImage(
                        model = store.logoUrl ?: "https://ui-avatars.com/api/?name=${store.name}&background=random",
                        contentDescription = store.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                }
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = store.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Row(verticalAlignment = Alignment.CenterVertically) {
                         Icon(
                            Icons.Default.Star,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = Orange40
                        )
                        Text(
                            text = " ${store.rating} (${store.reviewCount})",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = " • ",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.outline
                        )
                         Text(
                            text = if (store.deliveryFee == 0.0) "Ücretsiz" else "${store.deliveryFee.toInt()}₺",
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (store.deliveryFee == 0.0) Green40 else MaterialTheme.colorScheme.onSurface,
                            fontWeight = if (store.deliveryFee == 0.0) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                    
                    if (store.distance != null) {
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "${store.distance} km",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.Gray
                        )
                    }
                }
            }
        }
    }
}
