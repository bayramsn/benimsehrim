package com.benimsehrim.driver.feature.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NavigationScreen(
    taskId: String,
    onBack: () -> Unit,
    onComplete: () -> Unit
) {
    val kirsehir = LatLng(39.1425, 34.1709)
    val destination = LatLng(39.1500, 34.1800)
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(kirsehir, 15f)
    }

    var currentStep by remember { mutableStateOf("GOING_TO_PICKUP") } // GOING_TO_PICKUP, AT_PICKUP, ON_TRIP, COMPLETED

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Navigasyon") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Geri")
                    }
                },
                actions = {
                    IconButton(onClick = { /* Call customer */ }) {
                        Icon(Icons.Default.Phone, contentDescription = "Ara")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Full screen map
            GoogleMap(
                modifier = Modifier.fillMaxSize(),
                cameraPositionState = cameraPositionState,
                properties = MapProperties(isMyLocationEnabled = true)
            ) {
                // Pickup marker
                Marker(
                    state = MarkerState(position = kirsehir),
                    title = "Alış Noktası"
                )
                // Drop marker
                Marker(
                    state = MarkerState(position = destination),
                    title = "Bırakış Noktası"
                )
            }

            // Bottom Card
            Card(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Customer Info
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Ahmet Yılmaz", fontWeight = FontWeight.Bold)
                            Text(
                                when (currentStep) {
                                    "GOING_TO_PICKUP" -> "Müşteriye gidiliyor..."
                                    "AT_PICKUP" -> "Müşteri bekleniyor"
                                    "ON_TRIP" -> "Yolculuk devam ediyor"
                                    else -> "Tamamlandı"
                                },
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.Gray
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text("45₺", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = Color(0xFF4CAF50))
                            Text("3.2 km", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Address
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            if (currentStep == "GOING_TO_PICKUP" || currentStep == "AT_PICKUP")
                                Icons.Default.RadioButtonChecked
                            else
                                Icons.Default.LocationOn,
                            contentDescription = null,
                            tint = if (currentStep == "ON_TRIP") Color.Red else Color(0xFF4CAF50)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            if (currentStep == "GOING_TO_PICKUP" || currentStep == "AT_PICKUP")
                                "Atatürk Mah. 123 Sok."
                            else
                                "Cumhuriyet Mah. 456 Sok.",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Action Button
                    Button(
                        onClick = {
                            currentStep = when (currentStep) {
                                "GOING_TO_PICKUP" -> "AT_PICKUP"
                                "AT_PICKUP" -> "ON_TRIP"
                                "ON_TRIP" -> {
                                    onComplete()
                                    "COMPLETED"
                                }
                                else -> currentStep
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(56.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = when (currentStep) {
                                "GOING_TO_PICKUP" -> Color(0xFF2196F3)
                                "AT_PICKUP" -> Color(0xFFFFC107)
                                "ON_TRIP" -> Color(0xFF4CAF50)
                                else -> Color.Gray
                            }
                        )
                    ) {
                        Icon(
                            when (currentStep) {
                                "GOING_TO_PICKUP" -> Icons.Default.Navigation
                                "AT_PICKUP" -> Icons.Default.PersonAdd
                                "ON_TRIP" -> Icons.Default.CheckCircle
                                else -> Icons.Default.Done
                            },
                            contentDescription = null
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            when (currentStep) {
                                "GOING_TO_PICKUP" -> "Varış Noktasına Ulaştım"
                                "AT_PICKUP" -> "Müşteriyi Aldım"
                                "ON_TRIP" -> "Yolculuğu Tamamla"
                                else -> "Tamamlandı"
                            },
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}
