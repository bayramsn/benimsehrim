package com.benimsehrim.app.feature.courier

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CourierOrder(
    val id: String,
    val restaurantName: String,
    val customerName: String,
    val address: String,
    val lat: Double,
    val lng: Double,
    val status: String,
    val total: Double
)

data class CourierUiState(
    val activeOrders: List<CourierOrder> = emptyList(),
    val selectedOrder: CourierOrder? = null,
    val isOnline: Boolean = true,
    val isReady: Boolean = true, // !isBusy
    val dailyGoalTotal: Int = 15,
    val dailyGoalCurrent: Int = 12
)

@HiltViewModel
class CourierViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {
    private val _uiState = MutableStateFlow(CourierUiState())
    val uiState = _uiState.asStateFlow()

    init {
        loadMockOrders()
    }

    private fun loadMockOrders() {
        val mockOrders = listOf(
            CourierOrder("1", "Ahi Kasap", "Ahmet Yılmaz", "Terme Cad. No:5", 39.1435, 34.1720, "HAZIRLANIYOR", 450.0),
            CourierOrder("2", "Saray Pastanesi", "Ayşe Demir", "Ankara Cad. No:12", 39.1410, 34.1690, "TESLİMATTA", 120.0),
            CourierOrder("3", "Bizim Manav", "Mehmet Öztürk", "Lise Cad. No:8", 39.1450, 34.1750, "HAZIRLANIYOR", 85.0)
        )
        _uiState.value = _uiState.value.copy(activeOrders = mockOrders)
    }

    fun selectOrder(order: CourierOrder?) {
        _uiState.value = _uiState.value.copy(selectedOrder = order)
    }
    
    fun toggleOnline() {
        viewModelScope.launch {
            val newOnline = !_uiState.value.isOnline
            _uiState.value = _uiState.value.copy(
                isOnline = newOnline,
                isReady = newOnline 
            )
            // TODO: Implement specific Courier API endpoints
            // apiService.updateCourierStatus(...)
        }
    }
}
