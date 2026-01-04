package com.benimsehrim.app.feature.courier

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import com.benimsehrim.app.feature.taxi.GeoPoint
import com.benimsehrim.app.ui.theme.Green40
import com.benimsehrim.app.ui.theme.Orange40
import com.benimsehrim.app.R
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.annotations.MarkerOptions
import org.maplibre.android.annotations.PolylineOptions
import org.maplibre.android.geometry.LatLngBounds
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.compose.ui.platform.LocalLifecycleOwner

// Helper to convert our ViewModel's GeoPoint to MapLibre LatLng
private fun GeoPoint.toLatLng(): LatLng = LatLng(latitude, longitude)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CallCourierScreen(
    onNavigateBack: () -> Unit,
    viewModel: CallCourierViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    
    var mapLibreMap by remember { mutableStateOf<MapLibreMap?>(null) }
    val radarKey = context.getString(R.string.radar_publishable_key)
    val styleUrl = "https://api.radar.io/maps/styles/radar-default-v1?publishableKey=$radarKey"

    // Handle Map Lifecycle
    val lifecycleOwner = LocalLifecycleOwner.current
    val mapView = remember { MapView(context) }
    
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

    // Camera updates
    LaunchedEffect(uiState.pickupLocation, mapLibreMap) {
        uiState.pickupLocation?.let { location ->
            mapLibreMap?.animateCamera(CameraUpdateFactory.newLatLngZoom(location.toLatLng(), 16.0))
        }
    }
    LaunchedEffect(uiState.dropoffLocation, mapLibreMap) {
        uiState.dropoffLocation?.let { location ->
            mapLibreMap?.animateCamera(CameraUpdateFactory.newLatLngZoom(location.toLatLng(), 16.0))
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Kurye Çağır") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Geri")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        },
        floatingActionButton = {
             FloatingActionButton(
                onClick = {
                    val location = mapLibreMap?.locationComponent?.lastKnownLocation
                    if (location != null) {
                        mapLibreMap?.animateCamera(
                            CameraUpdateFactory.newLatLngZoom(LatLng(location.latitude, location.longitude), 17.0)
                        )
                    }
                },
                containerColor = Green40,
                contentColor = Color.White
            ) {
                Icon(Icons.Default.MyLocation, "Konum")
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize()) {
            
            // Map View
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = { 
                    mapView.apply {
                        getMapAsync { map ->
                            map.setStyle(styleUrl) { style ->
                                mapLibreMap = map
                                // Enable location component
                                val locationComponent = map.locationComponent
                                locationComponent.activateLocationComponent(
                                    org.maplibre.android.location.LocationComponentActivationOptions.builder(context, style).build()
                                )
                                locationComponent.isLocationComponentEnabled = true
                            }
                        }
                    }
                },
                update = { view ->
                    val map = mapLibreMap ?: return@AndroidView
                    map.clear()
                    
                    // Couriers
                    uiState.nearbyCouriers.forEach { courier ->
                        map.addMarker(MarkerOptions()
                            .position(LatLng(courier.lat, courier.lng))
                            .title("Kurye")
                        )
                    }
                    
                    // Pickup Marker
                    if (uiState.pickupLocation != null) {
                        map.addMarker(MarkerOptions()
                            .position(uiState.pickupLocation!!.toLatLng())
                            .title(uiState.pickupAddress.ifBlank { "Alınacak Yer" })
                        )
                    }
                    
                    // Dropoff Marker & Route
                    if (uiState.dropoffLocation != null) {
                        map.addMarker(MarkerOptions()
                            .position(uiState.dropoffLocation!!.toLatLng())
                            .title(uiState.dropoffAddress)
                        )

                        // Route Line (straight fallback as we don't have full polyline here yet)
                        val startPoint = uiState.pickupLocation ?: GeoPoint(39.1425, 34.1709)
                        map.addPolyline(PolylineOptions()
                            .add(startPoint.toLatLng())
                            .add(uiState.dropoffLocation!!.toLatLng())
                            .color(android.graphics.Color.BLUE)
                            .width(5f)
                        )
                    }
                }
            )

            // Bottom Control Panel
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .background(
                        MaterialTheme.colorScheme.surface, 
                        RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
                    )
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text("Paket Gönderimi", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

                // Addresses
                OutlinedTextField(
                    value = uiState.pickupAddress,
                    onValueChange = { viewModel.onPickupAddressChanged(it) },
                    label = { Text("Alınacak Adres") },
                    placeholder = { Text("Mevcut Konum") },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = { Icon(Icons.Default.MyLocation, null, tint = Green40) },
                    trailingIcon = {
                        if (uiState.isLoading && uiState.pickupAddress.length > 3) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else if (uiState.pickupAddress.isNotEmpty()) {
                             IconButton(onClick = { viewModel.onPickupAddressChanged("") }) {
                                 Icon(Icons.Default.Clear, "Temizle")
                             }
                        }
                    },
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true
                )

                OutlinedTextField(
                    value = uiState.dropoffAddress,
                    onValueChange = { viewModel.onDropoffAddressChanged(it) },
                    label = { Text("Teslim Edilecek Adres") },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = { Icon(Icons.Default.LocationOn, null, tint = Color.Red) },
                    trailingIcon = {
                        if (uiState.isLoading && uiState.dropoffAddress.length > 3) {
                             CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else if (uiState.dropoffAddress.isNotEmpty()) {
                             IconButton(onClick = { viewModel.onDropoffAddressChanged("") }) {
                                 Icon(Icons.Default.Clear, "Temizle")
                             }
                        }
                    },
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true
                )
                
                // Package Desc
                OutlinedTextField(
                    value = uiState.packageDescription,
                    onValueChange = { viewModel.onPackageDescriptionChanged(it) },
                    label = { Text("Paket İçeriği") },
                     placeholder = { Text("Örn: Dosya, Anahtar") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                // Courier Type Selection
                Row(
                   modifier = Modifier.fillMaxWidth(),
                   horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    val types = listOf("MOTO" to "Moto Kurye", "CAR" to "Araç Kurye")
                    types.forEach { (type, label) ->
                        val isSelected = uiState.courierType == type
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) Green40 else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier
                                .weight(1f)
                                .clickable { viewModel.onCourierTypeChanged(type) }
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Icon(
                                    if (type == "MOTO") Icons.Default.TwoWheeler else Icons.Default.LocalTaxi,
                                    contentDescription = null,
                                    tint = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    label,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        }
                    }
                }

                // Fare & Action
                if (uiState.fareEstimate != null) {
                     val fare = uiState.fareEstimate!!
                     Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.secondaryContainer, RoundedCornerShape(12.dp))
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Tahmini Ücret", style = MaterialTheme.typography.labelMedium)
                            Text(
                                "${fare.amount} ${fare.currency}",
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSecondaryContainer
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text("${fare.distanceKm} km", style = MaterialTheme.typography.bodyMedium)
                            Text("${fare.durationMin} dk", style = MaterialTheme.typography.bodyMedium)
                        }
                    }

                    Button(
                        onClick = { /* Implement Call */ },
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Green40),
                        enabled = uiState.pickupAddress.isNotBlank() && uiState.dropoffAddress.isNotBlank()
                    ) {
                        Icon(Icons.Default.TwoWheeler, null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(if (uiState.isLoading) "Hesaplanıyor..." else "Kurye Çağır")
                    }
                }
            }
        }
    }
}
