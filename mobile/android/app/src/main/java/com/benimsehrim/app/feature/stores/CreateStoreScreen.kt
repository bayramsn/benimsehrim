package com.benimsehrim.app.feature.stores

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateStoreScreen(
    onNavigateBack: () -> Unit
) {
    var storeName by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var submitted by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Yeni Mağaza Aç") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Geri")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (submitted) {
                Text(
                    "Başvurunuz Alındı! 🎉\nEkibimiz en kısa sürede sizinle iletişime geçecektir.",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.primary
                )
                Button(onClick = onNavigateBack) {
                    Text("Ana Sayfaya Dön")
                }
            } else {
                OutlinedTextField(
                    value = storeName,
                    onValueChange = { storeName = it },
                    label = { Text("Mağaza Adı") },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = address,
                    onValueChange = { address = it },
                    label = { Text("Adres") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 3
                )
                
                Text("Kategori Seçimi", style = MaterialTheme.typography.titleMedium)
                
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("Restoran", "Market", "Kasap", "Manav").forEach { cat ->
                        FilterChip(
                            selected = selectedCategory == cat,
                            onClick = { selectedCategory = cat },
                            label = { Text(cat) }
                        )
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                Button(
                    onClick = { submitted = true },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    enabled = storeName.isNotBlank() && selectedCategory.isNotBlank()
                ) {
                    Text("Başvuruyu Gönder")
                }
            }
        }
    }
}
