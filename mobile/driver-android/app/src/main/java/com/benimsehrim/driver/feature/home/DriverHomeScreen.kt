package com.benimsehrim.driver.feature.home

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker

/**
 * Driver Home Screen with FREE OpenStreetMap
 * No Google Maps API key needed!
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DriverHomeScreen(
    viewModel: DriverHomeViewModel = hiltViewModel(),
    onNavigateToTask: (String) -> Unit = {},
    onNavigateToEarnings: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    // Configure OSMDroid
    LaunchedEffect(Unit) {
        Configuration.getInstance().userAgentValue = "BenimSehrim/1.0"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sürücü Paneli") },
                actions = {
                    IconButton(onClick = onNavigateToEarnings) {
                        Icon(Icons.Default.AccountBalanceWallet, "Kazançlar")
                    }
                }
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // OpenStreetMap View
            OSMMapView(
                modifier = Modifier.fillMaxSize(),
                currentLocation = uiState.currentLocation,
                activeTask = uiState.activeTask
            )

            // Mode Toggle (Taksi / Kurye)
            Row(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(16.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(MaterialTheme.colorScheme.surface)
            ) {
                FilterChip(
                    selected = uiState.mode == DriverMode.TAXI,
                    onClick = { viewModel.setMode(DriverMode.TAXI) },
                    label = { Text("🚕 Taksi") },
                    modifier = Modifier.padding(4.dp)
                )
                FilterChip(
                    selected = uiState.mode == DriverMode.COURIER,
                    onClick = { viewModel.setMode(DriverMode.COURIER) },
                    label = { Text("📦 Kurye") },
                    modifier = Modifier.padding(4.dp)
                )
            }

            // Online/Offline Toggle
            OnlineStatusCard(
                isOnline = uiState.isOnline,
                onToggle = { viewModel.toggleOnline() },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
            )

            // Active Task Card
            uiState.activeTask?.let { task ->
                ActiveTaskCard(
                    task = task,
                    onAccept = { viewModel.acceptTask(task.id) },
                    onReject = { viewModel.rejectTask(task.id) },
                    onNavigate = { onNavigateToTask(task.id) },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 100.dp)
                        .padding(horizontal = 16.dp)
                )
            }

            // Daily Earnings Badge
            EarningsBadge(
                earnings = uiState.todayEarnings,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(top = 80.dp, end = 16.dp)
            )
        }
    }
}

@Composable
fun OSMMapView(
    modifier: Modifier = Modifier,
    currentLocation: GeoPoint?,
    activeTask: DriverTask?
) {
    val context = LocalContext.current

    AndroidView(
        factory = { ctx ->
            MapView(ctx).apply {
                // Use OpenStreetMap tiles (FREE!)
                setTileSource(TileSourceFactory.MAPNIK)
                setMultiTouchControls(true)
                controller.setZoom(15.0)

                // Default to Kırşehir center
                controller.setCenter(GeoPoint(39.8468, 34.0288))
            }
        },
        update = { mapView ->
            // Update current location
            currentLocation?.let { location ->
                mapView.controller.setCenter(location)

                // Add current location marker
                mapView.overlays.clear()
                val marker = Marker(mapView).apply {
                    position = location
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                    title = "Konumunuz"
                    icon = ContextCompat.getDrawable(context, android.R.drawable.ic_menu_mylocation)
                }
                mapView.overlays.add(marker)
            }

            // Add task destination marker
            activeTask?.let { task ->
                val destMarker = Marker(mapView).apply {
                    position = GeoPoint(task.destinationLat, task.destinationLng)
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                    title = task.destinationAddress
                    icon = ContextCompat.getDrawable(context, android.R.drawable.ic_menu_compass)
                }
                mapView.overlays.add(destMarker)
            }

            mapView.invalidate()
        },
        modifier = modifier
    )
}

@Composable
fun OnlineStatusCard(
    isOnline: Boolean,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isOnline) Color(0xFF4CAF50) else MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = if (isOnline) "Çevrimiçi" else "Çevrimdışı",
                    style = MaterialTheme.typography.titleMedium,
                    color = if (isOnline) Color.White else MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = if (isOnline) "Görev bekleniyor..." else "Görev almak için açın",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isOnline) Color.White.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Switch(
                checked = isOnline,
                onCheckedChange = { onToggle() },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = Color.White.copy(alpha = 0.3f)
                )
            )
        }
    }
}

@Composable
fun ActiveTaskCard(
    task: DriverTask,
    onAccept: () -> Unit,
    onReject: () -> Unit,
    onNavigate: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF3E0))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = if (task.type == "TAXI") "🚕 Yolculuk Talebi" else "📦 Teslimat",
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = "${task.estimatedFare}₺",
                    style = MaterialTheme.typography.titleLarge,
                    color = Color(0xFF006E24)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.LocationOn, "Konum", tint = Color.Gray, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(task.pickupAddress, style = MaterialTheme.typography.bodySmall)
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Flag, "Hedef", tint = Color(0xFF006E24), modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(task.destinationAddress, style = MaterialTheme.typography.bodySmall)
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)
                ) {
                    Text("Reddet")
                }
                Button(
                    onClick = if (task.status == "PENDING") onAccept else onNavigate,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF006E24))
                ) {
                    Text(if (task.status == "PENDING") "Kabul Et" else "Navigasyon")
                }
            }
        }
    }
}

@Composable
fun EarningsBadge(
    earnings: Double,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = Color(0xFF006E24))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Default.AccountBalanceWallet, "Kazanç", tint = Color.White)
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "${earnings.toInt()}₺",
                style = MaterialTheme.typography.titleMedium,
                color = Color.White
            )
        }
    }
}

// Models
enum class DriverMode { TAXI, COURIER }

data class DriverTask(
    val id: String,
    val type: String,
    val status: String,
    val pickupAddress: String,
    val pickupLat: Double,
    val pickupLng: Double,
    val destinationAddress: String,
    val destinationLat: Double,
    val destinationLng: Double,
    val estimatedFare: Double,
    val estimatedDuration: Int
)
