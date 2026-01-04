package com.benimsehrim.app.feature.courier

import android.content.Context
import android.location.Geocoder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.network.ApiService
import com.benimsehrim.app.feature.taxi.FareEstimate
import com.benimsehrim.app.feature.taxi.NearbyDriver
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import com.benimsehrim.app.feature.taxi.GeoPoint
import io.radar.sdk.Radar
import java.util.Locale
import java.util.EnumSet
import javax.inject.Inject
import kotlin.math.roundToInt

data class CallCourierUiState(
    val pickupAddress: String = "",
    val dropoffAddress: String = "",
    val packageDescription: String = "",
    val courierType: String = "MOTO", // MOTO or CAR
    val nearbyCouriers: List<NearbyDriver> = emptyList(),
    val fareEstimate: FareEstimate? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val dropoffLocation: GeoPoint? = null,
    val pickupLocation: GeoPoint? = null
)

@HiltViewModel
class CallCourierViewModel @Inject constructor(
    private val apiService: ApiService,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(CallCourierUiState())
    val uiState: StateFlow<CallCourierUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    init {
        loadNearbyCouriers()
    }

    private fun loadNearbyCouriers() {
        // Mock couriers
        val couriers = listOf(
            NearbyDriver("1", 39.1435, 34.1718, 90f),
            NearbyDriver("2", 39.1415, 34.1705, 0f)
        )
        _uiState.update { it.copy(nearbyCouriers = couriers) }
    }

    fun onPickupAddressChanged(address: String) {
        _uiState.update { it.copy(pickupAddress = address) }
        performSearch(address) { location ->
            _uiState.update { it.copy(pickupLocation = location) }
            recalculateRoute()
        }
    }

    fun onDropoffAddressChanged(address: String) {
        _uiState.update { it.copy(dropoffAddress = address) }
        performSearch(address) { location ->
            _uiState.update { it.copy(dropoffLocation = location) }
            recalculateRoute()
        }
    }
    
    fun onPackageDescriptionChanged(desc: String) {
        _uiState.update { it.copy(packageDescription = desc) }
    }
    
    fun onCourierTypeChanged(type: String) {
        _uiState.update { it.copy(courierType = type) }
        recalculateRoute()
    }

    private fun performSearch(query: String, onResult: (GeoPoint?) -> Unit) {
        searchJob?.cancel()
        val trimmedQuery = query.trim()
        
        if (trimmedQuery.length < 3) {
            onResult(null)
            return
        }
        
        // Bias search to Kırşehir
        val searchQuery = if (trimmedQuery.contains("kırşehir", ignoreCase = true) || trimmedQuery.contains("kirsehir", ignoreCase = true)) {
            trimmedQuery
        } else {
            "$trimmedQuery, Kırşehir"
        }

        searchJob = viewModelScope.launch {
            delay(500) // Debounce
            _uiState.update { it.copy(isLoading = true) }
            
            try {
                Radar.geocode(searchQuery) { status, addresses ->
                    val location = if (status == Radar.RadarStatus.SUCCESS && !addresses.isNullOrEmpty()) {
                        GeoPoint(addresses[0].coordinate.latitude, addresses[0].coordinate.longitude)
                    } else {
                        null
                    }
                    
                    viewModelScope.launch(Dispatchers.Main) {
                        onResult(location)
                        _uiState.update { it.copy(isLoading = false) }
                    }
                }
            } catch (e: Exception) {
                viewModelScope.launch(Dispatchers.Main) {
                    onResult(null)
                    _uiState.update { it.copy(isLoading = false) }
                }
            }
        }
    }

    private fun recalculateRoute() {
        val start = _uiState.value.pickupLocation ?: GeoPoint(39.1425, 34.1709)
        val end = _uiState.value.dropoffLocation
        
        if (end != null) {
            calculateFare(start, end)
        } else {
            _uiState.update { it.copy(fareEstimate = null) }
        }
    }

    private fun calculateFare(start: GeoPoint, end: GeoPoint) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            val origin = android.location.Location("").apply {
                latitude = start.latitude
                longitude = start.longitude
            }
            val destination = android.location.Location("").apply {
                latitude = end.latitude
                longitude = end.longitude
            }

            Radar.getDistance(
                origin, 
                destination, 
                EnumSet.of(Radar.RadarRouteMode.CAR),
                Radar.RadarRouteUnits.METRIC
            ) { status, routes ->
                if (status == Radar.RadarStatus.SUCCESS && routes != null && routes.car != null) {
                    val route = routes.car!!
                    val distanceKm = (route.distance?.value ?: 0.0) / 1000.0
                    val durationMin = route.duration?.value?.toInt() ?: 0
                    
                    // Pricing Logic
                    val isMoto = _uiState.value.courierType == "MOTO"
                    val baseFare = if (isMoto) 30.0 else 50.0
                    val perKm = if (isMoto) 5.0 else 8.0
                    
                    val amount = baseFare + (distanceKm * perKm)

                    val fare = FareEstimate(
                        amount = (amount / 5).roundToInt() * 5.0, // Round to nearest 5
                        currency = "₺",
                        durationMin = durationMin,
                        distanceKm = (distanceKm * 10).roundToInt() / 10.0
                    )
                    
                    _uiState.update { it.copy(
                        isLoading = false,
                        fareEstimate = fare
                    )}
                } else {
                    _uiState.update { it.copy(isLoading = false) }
                }
            }
        }
    }
}
