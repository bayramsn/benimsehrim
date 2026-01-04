package com.benimsehrim.app.feature.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesScreen(
    onNavigateToStore: (String) -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val favoriteStores = uiState.popularStores.filter { it.isFavorite }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Favorilerim", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Geri")
                    }
                }
            )
        }
    ) { padding ->
        if (favoriteStores.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Henüz favori mağazan yok.")
            }
        } else {
            LazyColumn(modifier = Modifier.padding(padding)) {
                items(favoriteStores) { store ->
                    // Reusing StoreCard from HomeScreen might need moving StoreCard to a common file or duplicated here.
                    // For simplicity, we will assume StoreCard is internal to HomeScreen.kt.
                    // To fix this properly, I should move StoreCard to a components file.
                    // But I cannot easily move code without view/replace.
                    // I will implement a Simple Store Item here for speed.
                    ListItem(
                        headlineContent = { Text(store.name) },
                        supportingContent = { Text("${store.rating} ★") },
                        leadingContent = { Text("🏪") },
                        trailingContent = { 
                            Button(onClick = { onNavigateToStore(store.id) }) { Text("Git") } 
                        }
                    )
                    Divider()
                }
            }
        }
    }
}
