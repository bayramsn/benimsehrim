package com.benimsehrim.app.feature.taxi

import android.os.Bundle
import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MyLocation
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
import com.benimsehrim.app.ui.components.GradientButton
import com.benimsehrim.app.ui.theme.*
import kotlinx.coroutines.launch
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.MapLibreMapOptions
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style
import org.maplibre.android.annotations.MarkerOptions
import org.maplibre.android.annotations.PolylineOptions
import org.maplibre.android.location.LocationComponentActivationOptions

// Helper to convert our ViewModel's GeoPoint to MapLibre LatLng
private fun GeoPoint.toLatLng(): LatLng = LatLng(latitude, longitude)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaxiScreen(
    onNavigateToRide: (String) -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: TaxiViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val radarKey = remember { context.getString(R.string.radar_publishable_key) }
    val styleUrl = remember(radarKey) { 
        "https://api.radar.io/maps/styles/radar-default-v1?publishableKey=$radarKey" 
    }

    // 1. MapView Initialization & Lifecycle
    // We explicitly enable TEXTURE MODE which is required for Emulators to render correctly
    val mapView = remember {
        val options = MapLibreMapOptions.createFromAttributes(context).textureMode(true)
        MapView(context, options).apply {
            onCreate(Bundle())
        }
    }

    var mapLibreMap by remember { mutableStateOf<MapLibreMap?>(null) }

    // 2. Lifecycle Observer
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

    // 3. Map Logic - Camera & Markers update
    LaunchedEffect(mapLibreMap, uiState.pickupLocation, uiState.dropoffLocation, uiState.routePoints) {
        val map = mapLibreMap ?: return@LaunchedEffect
        
        map.clear()

        val points = mutableListOf<LatLng>()

        // Add Pickup
        uiState.pickupLocation?.let {
            val position = it.toLatLng()
            points.add(position)
            map.addMarker(MarkerOptions().position(position).title("Başlangıç"))
        }

        // Add Dropoff
        uiState.dropoffLocation?.let {
            val position = it.toLatLng()
            points.add(position)
            map.addMarker(MarkerOptions().position(position).title("Hedef"))
        }

        // Add Route
        if (uiState.routePoints.size > 1) {
            val routeLatLngs = uiState.routePoints.map { it.toLatLng() }
            points.addAll(routeLatLngs)
            map.addPolyline(
                PolylineOptions()
                    .addAll(routeLatLngs)
                    .color(android.graphics.Color.parseColor("#00E676"))
                    .width(6f)
            )
        }
        
        // Add Drivers
        uiState.nearbyDrivers.forEach { driver ->
             map.addMarker(MarkerOptions()
                 .position(LatLng(driver.lat, driver.lng))
                 .title("Taksi"))
        }

        // Camera Animation Logic
        try {
            if (points.isNotEmpty()) {
                if (points.size == 1) {
                    // Single Point (User location or pickup)
                    val pos = org.maplibre.android.camera.CameraPosition.Builder()
                        .target(points[0])
                        .zoom(16.0) 
                        .tilt(45.0) // Tilt for 3D effect
                        .build()
                    map.animateCamera(CameraUpdateFactory.newCameraPosition(pos), 1000)
                } else {
                    // Route or Multiple Points
                    val bounds = LatLngBounds.Builder().includes(points).build()
                    map.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds, 150), 1000)
                }
            }
        } catch (e: Exception) {
            // Handle invalid bounds
        }
    }

    Scaffold(
        containerColor = Color.Black
    ) { padding ->
        Box(modifier = Modifier
            .padding(padding)
            .fillMaxSize()) {
            
            // MAP VIEW
            AndroidView(
                factory = { 
                    mapView.apply {
                        getMapAsync { map ->
                            map.setStyle(styleUrl) { style ->
                                mapLibreMap = map
                                map.uiSettings.isLogoEnabled = false
                                map.uiSettings.isAttributionEnabled = false
                                map.uiSettings.isTiltGesturesEnabled = true
                                map.uiSettings.isRotateGesturesEnabled = true
                                
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

            // UI OVERLAYS
            
            // 1. Back & My Location (Top)
            Row(
                modifier = Modifier
                    .statusBarsPadding()
                    .padding(16.dp)
                    .fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    onClick = onNavigateBack,
                    shape = CircleShape,
                    color = SurfaceDark.copy(alpha = 0.9f),
                    tonalElevation = 8.dp
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Geri",
                        modifier = Modifier.padding(12.dp),
                        tint = TextPrimary
                    )
                }
            }

            // 2. Address Input Card
            Surface(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
                    .padding(bottom = 200.dp)
                    .fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                color = SurfaceDark.copy(alpha = 0.95f),
                tonalElevation = 8.dp
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.width(24.dp)
                        ) {
                            Box(modifier = Modifier.size(10.dp).background(Primary, CircleShape))
                            Box(modifier = Modifier.width(1.dp).height(40.dp).background(Primary.copy(alpha = 0.3f)))
                            Box(modifier = Modifier.size(10.dp).background(Error, RoundedCornerShape(2.dp)))
                        }
                        
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .padding(start = 12.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                             BasicTextField(
                                value = uiState.pickupAddress,
                                onValueChange = { viewModel.onPickupAddressChanged(it) },
                                textStyle = MaterialTheme.typography.bodyMedium.copy(color = TextPrimary),
                                decorationBox = { innerTextField ->
                                    if (uiState.pickupAddress.isEmpty()) {
                                        Text("Nereden?", color = TextSecondary, style = MaterialTheme.typography.bodyMedium)
                                    }
                                    innerTextField()
                                }
                            )
                            Divider(color = CardOutline, thickness = 0.5.dp)
                             Box(modifier = Modifier.fillMaxWidth()) {
                                BasicTextField(
                                    value = uiState.dropoffAddress,
                                    onValueChange = { viewModel.onDropoffAddressChanged(it) },
                                    modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                                    textStyle = MaterialTheme.typography.titleMedium.copy(
                                        color = TextPrimary, 
                                        fontWeight = FontWeight.Bold
                                    ),
                                    decorationBox = { innerTextField ->
                                        if (uiState.dropoffAddress.isEmpty()) {
                                            Text("Nereye gidiyoruz?", color = Primary.copy(alpha = 0.7f), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                                        }
                                        innerTextField()
                                    }
                                )
                                if (uiState.isLoading || uiState.isSearching) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(20.dp).align(Alignment.CenterEnd),
                                        color = Primary, strokeWidth = 2.dp
                                    )
                                }
                            }
                        }
                    }
                    if (uiState.dropoffAddress.length >= 3 && uiState.dropoffLocation == null && !uiState.isSearching) {
                        Text("Adres bulunamadı.", color = Error, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(start = 36.dp))
                    }
                }
            }

            // 3. Bottom Sheet
             Surface(
                modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth(),
                color = SurfaceDark,
                shape = RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp),
                tonalElevation = 12.dp
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(20.dp)
                ) {
                    val fare = uiState.fareEstimate
                    if (fare != null) {
                         Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("Tahmini Tutar", style = MaterialTheme.typography.labelMedium, color = TextSecondary)
                                Text("${fare.amount} ${fare.currency}", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold, color = Primary)
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text("${fare.distanceKm} km • ${fare.durationMin} dk", style = MaterialTheme.typography.bodyMedium, color = TextPrimary)
                                Text("En Yakın Taksi: 3 dk", style = MaterialTheme.typography.bodySmall, color = Primary)
                            }
                        }
                    } else {
                        Spacer(modifier = Modifier.height(0.dp))
                    }
                    GradientButton(
                        text = if (uiState.isLoading) "Hesaplanıyor..." else "Şimdi Çağır",
                        onClick = { 
                            if (uiState.dropoffLocation != null) onNavigateToRide("mock_1")
                            else Toast.makeText(context, "Lütfen bir hedef seçin", Toast.LENGTH_SHORT).show()
                        },
                        modifier = Modifier.fillMaxWidth().height(56.dp),
                        enabled = !uiState.isLoading
                    )
                }
            }
            
            FloatingActionButton(
                onClick = {
                    try {
                        val location = mapLibreMap?.locationComponent?.lastKnownLocation
                        if (location != null) {
                            val pos = org.maplibre.android.camera.CameraPosition.Builder()
                                .target(LatLng(location.latitude, location.longitude))
                                .zoom(16.0).tilt(45.0).build()
                            mapLibreMap?.animateCamera(CameraUpdateFactory.newCameraPosition(pos))
                        }
                    } catch (e: Exception) {}
                },
                modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp).padding(bottom = 220.dp),
                containerColor = SurfaceDark.copy(alpha = 0.9f),
                contentColor = Primary,
                shape = CircleShape
            ) {
                Icon(Icons.Default.MyLocation, "Konum")
            }
        }
    }
}
