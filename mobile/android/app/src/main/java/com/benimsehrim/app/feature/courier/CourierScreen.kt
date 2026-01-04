package com.benimsehrim.app.feature.courier

import android.os.Bundle
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.benimsehrim.app.R
import com.benimsehrim.app.ui.theme.*
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapLibreMapOptions
import org.maplibre.android.maps.MapView
import org.maplibre.android.annotations.MarkerOptions
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import org.maplibre.android.location.LocationComponentActivationOptions

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CourierScreen(
    onNavigateBack: () -> Unit,
    viewModel: CourierViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    
    val radarKey = remember { context.getString(R.string.radar_publishable_key) }
    val styleUrl = remember(radarKey) { 
        "https://api.radar.io/maps/styles/radar-default-v1?publishableKey=$radarKey" 
    }

    // 1. MapView Initialization & Lifecycle
    // Enable Texture Mode for Emulator compatibility
    val mapView = remember {
        val options = MapLibreMapOptions.createFromAttributes(context).textureMode(true)
        MapView(context, options).apply {
            onCreate(Bundle())
        }
    }
    
    var mapLibreMap by remember { mutableStateOf<MapLibreMap?>(null) }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> mapView.onStart()
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                Lifecycle.Event.ON_STOP -> mapView.onStop()
                Lifecycle.Event.ON_DESTROY -> mapView.onDestroy()
                else -> {}
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    // 2. Map Logic
    LaunchedEffect(mapLibreMap, uiState.activeOrders, uiState.isOnline) {
        val map = mapLibreMap ?: return@LaunchedEffect
        map.clear()

        if (uiState.isOnline) {
             uiState.activeOrders.forEach { order ->
                map.addMarker(MarkerOptions()
                    .position(LatLng(order.lat, order.lng))
                    .title("${order.restaurantName} - ${order.customerName}")
                    .snippet(order.status)
                )
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Column {
                        Text("Kurye Modu", style = MaterialTheme.typography.titleLarge)
                        Text(
                            if (uiState.isOnline) "Çevrimiçi" else "Çevrimdışı", 
                            style = MaterialTheme.typography.labelMedium,
                            color = if (uiState.isOnline) Green40 else Color.Gray
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Çıkış")
                    }
                },
                actions = {
                    Switch(
                        checked = uiState.isOnline,
                        onCheckedChange = { viewModel.toggleOnline() },
                        colors = SwitchDefaults.colors(checkedThumbColor = Green40)
                    )
                }
            )
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize()) {
            
            // MAP
            AndroidView(
                factory = { 
                    mapView.apply {
                        getMapAsync { map ->
                            map.setStyle(styleUrl) { style ->
                                mapLibreMap = map
                                try {
                                    val locationComponent = map.locationComponent
                                    locationComponent.activateLocationComponent(
                                        LocationComponentActivationOptions.builder(context, style).build()
                                    )
                                    locationComponent.isLocationComponentEnabled = true
                                } catch (e: Exception) { }
                            }
                        }
                    }
                },
                modifier = Modifier.fillMaxSize()
            )

            // OVERLAYS
            // OVERLAYS
            
            // Top Status Card
            Column(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(16.dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                 Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(SurfaceDark.copy(alpha = 0.9f))
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Görev Almaya Hazırım", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
                        Text(if(uiState.isOnline) "Paket bekleniyor" else "Şu an görev almıyorsunuz", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                    Switch(
                        checked = uiState.isOnline,
                        onCheckedChange = { viewModel.toggleOnline() },
                        colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Green40)
                    )
                }

                if (uiState.isOnline) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = { /* Break */ },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = SurfaceDark.copy(alpha = 0.9f)),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text("30 Dk Mola", color = TextPrimary)
                        }
                         Button(
                            onClick = { /* Stats */ },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = SurfaceDark.copy(alpha = 0.9f)),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text("Hedef: 12/15", color = Green40)
                        }
                    }
                }
            }

            if (uiState.selectedOrder != null) {
                val order = uiState.selectedOrder!!
                Card(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .padding(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(order.restaurantName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.weight(1f))
                            Text("${order.total.toInt()}₺", style = MaterialTheme.typography.titleMedium, color = Green40)
                        }
                        Divider(modifier = Modifier.padding(vertical = 8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Person, null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(order.customerName)
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.LocationOn, null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(order.address, maxLines = 1)
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = { viewModel.selectOrder(null) },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(containerColor = Color.Gray)
                            ) { Text("Kapat") }
                            Button(
                                onClick = { /* Navigate */ },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(containerColor = Green40)
                            ) {
                                Icon(Icons.Default.Navigation, null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Rotayı Çiz")
                            }
                        }
                    }
                }
            }
        }
    }
}
