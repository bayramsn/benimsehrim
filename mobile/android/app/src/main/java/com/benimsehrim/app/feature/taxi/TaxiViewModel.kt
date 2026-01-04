package com.benimsehrim.app.feature.taxi

import android.content.Context
import android.location.Geocoder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.network.ApiService
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
import io.radar.sdk.Radar
import io.radar.sdk.model.RadarAddress
import io.radar.sdk.model.RadarRoute
import android.location.Location
import java.text.Normalizer
import android.widget.Toast
import java.util.Locale
import java.util.EnumSet
import java.net.URL
import org.json.JSONArray
import org.json.JSONObject
import javax.inject.Inject
import kotlin.math.roundToInt

// Custom GeoPoint to avoid map-library specific dependencies in ViewModel
data class GeoPoint(val latitude: Double, val longitude: Double)

data class NearbyDriver(
    val id: String,
    val lat: Double,
    val lng: Double,
    val rotation: Float
)

data class FareEstimate(
    val amount: Double,
    val currency: String,
    val durationMin: Int,
    val distanceKm: Double
)

data class TaxiUiState(
    val pickupAddress: String = "",
    val dropoffAddress: String = "",
    val nearbyDrivers: List<NearbyDriver> = emptyList(),
    val fareEstimate: FareEstimate? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val dropoffLocation: GeoPoint? = null,
    val pickupLocation: GeoPoint? = null,
    val isSearching: Boolean = false,
    val routePoints: List<GeoPoint> = emptyList()
)

@HiltViewModel
class TaxiViewModel @Inject constructor(
    private val apiService: ApiService,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(TaxiUiState(
        pickupLocation = GeoPoint(39.1425, 34.1709), // Default to Kirsehir Center
        pickupAddress = "Kırşehir Merkez"
    ))
    val uiState: StateFlow<TaxiUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null
    private var fareJob: Job? = null

    init {
        loadNearbyDrivers()
    }

    private fun loadNearbyDrivers() {
        viewModelScope.launch {
            // Initial mock drivers
            var drivers = listOf(
                NearbyDriver("1", 39.1430, 34.1715, 45f),
                NearbyDriver("2", 39.1420, 34.1700, 180f),
                NearbyDriver("3", 39.1440, 34.1725, 270f)
            )
            _uiState.update { it.copy(nearbyDrivers = drivers) }

            // Simulate movement
            while (true) {
                delay(3000)
                drivers = drivers.map { d ->
                    d.copy(
                        lat = d.lat + (Math.random() - 0.5) * 0.0002,
                        lng = d.lng + (Math.random() - 0.5) * 0.0002,
                        rotation = (d.rotation + (Math.random() * 20 - 10)).toFloat()
                    )
                }
                _uiState.update { it.copy(nearbyDrivers = drivers) }
            }
        }
    }

    private fun reverseGeocode(location: GeoPoint, onResult: (String) -> Unit) {
        val androidLocation = Location("").apply {
            latitude = location.latitude
            longitude = location.longitude
        }

        Radar.reverseGeocode(androidLocation) { status, addresses ->
            val addressLabel = if (status == Radar.RadarStatus.SUCCESS && !addresses.isNullOrEmpty()) {
                addresses[0].formattedAddress ?: "Bilinmeyen Konum"
            } else {
                "Bilinmeyen Konum"
            }
            viewModelScope.launch(Dispatchers.Main) {
                onResult(addressLabel)
            }
        }
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
            if (location != null) {
                _uiState.update { it.copy(dropoffLocation = location) }
                recalculateRoute()
            } else {
                _uiState.update { it.copy(dropoffLocation = null, fareEstimate = null, routePoints = emptyList()) }
            }
        }
    }

    private fun performSearch(query: String, onResult: (GeoPoint?) -> Unit) {
        searchJob?.cancel()
        val trimmedQuery = query.trim()
        
        if (trimmedQuery.length < 3) {
            onResult(null)
            _uiState.update { it.copy(isSearching = false) }
            return
        }

        // Bias search to Kırşehir
        val searchQuery = if (trimmedQuery.contains("kırşehir", ignoreCase = true) || trimmedQuery.contains("kirsehir", ignoreCase = true)) {
            trimmedQuery
        } else {
            "$trimmedQuery, Kırşehir"
        }

        _uiState.update { it.copy(isSearching = true) }
        searchJob = viewModelScope.launch {
            try {
                delay(300)
                Radar.geocode(searchQuery) { status, addresses ->
                    val location = if (status == Radar.RadarStatus.SUCCESS && !addresses.isNullOrEmpty()) {
                        GeoPoint(addresses[0].coordinate.latitude, addresses[0].coordinate.longitude)
                    } else {
                        null
                    }
                    
                    viewModelScope.launch(Dispatchers.Main) {
                        onResult(location)
                        _uiState.update { it.copy(isSearching = false) }
                    }
                }
            } catch (e: Exception) {
                viewModelScope.launch(Dispatchers.Main) {
                    onResult(null)
                    _uiState.update { it.copy(isSearching = false) }
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
        val currentState = _uiState.value
        if (currentState.fareEstimate != null && 
            currentState.pickupLocation == start && 
            currentState.dropoffLocation == end) return

        fareJob?.cancel()
        fareJob = viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            val origin = Location("").apply {
                latitude = start.latitude
                longitude = start.longitude
            }
            val destination = Location("").apply {
                latitude = end.latitude
                longitude = end.longitude
            }

            Radar.getDistance(
                origin, 
                destination, 
                java.util.EnumSet.of(Radar.RadarRouteMode.CAR),
                Radar.RadarRouteUnits.METRIC
            ) { status, routes ->
                if (status == Radar.RadarStatus.SUCCESS && routes != null && routes.car != null) {
                    val route = routes.car!!
                    val distanceKm = (route.distance?.value ?: 0.0) / 1000.0
                    val durationMin = route.duration?.value ?: 0.0
                    
                    // Route points fallback (straight line if geometry is missing from distance API)
                    // Note: Radar's distance API might not return full geometry. 
                    // If needed, we'd use getRoutes for full polyline.
                    val pts = listOf(start, end) 

                    val amount = 20.0 + (distanceKm * 15.0)
                    val fare = FareEstimate(
                        amount = (amount / 1.0).roundToInt().toDouble(),
                        currency = "₺",
                        durationMin = durationMin.toInt(),
                        distanceKm = (distanceKm * 10).roundToInt() / 10.0
                    )
                    
                    _uiState.update { it.copy(
                        fareEstimate = fare,
                        routePoints = pts,
                        isLoading = false
                    )}
                } else {
                    _uiState.update { it.copy(isLoading = false, fareEstimate = null) }
                }
            }
        }
    }

    fun setPickupFromCurrentLocation(location: GeoPoint) {
        _uiState.update { it.copy(pickupLocation = location, isLoading = true) }
        reverseGeocode(location) { address ->
            _uiState.update { it.copy(pickupAddress = address, isLoading = false) }
            recalculateRoute()
        }
    }

    fun onMapCameraMoved(newCenter: GeoPoint) {
        // This can be used for "Pin on map" style selection
        // For now, let's keep it simple
    }
}
