package com.benimsehrim.driver.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DriverTask(
    val id: String,
    val type: String, // TAXI, DELIVERY
    val customerName: String,
    val customerPhone: String,
    val pickupAddress: String,
    val dropAddress: String,
    val distance: Double,
    val estimatedFare: Double,
    val status: String // PENDING, ACCEPTED, PICKED_UP, COMPLETED
)

data class DriverHomeUiState(
    val driverName: String = "Demo Şoför",
    val driverType: String = "TAXI", // TAXI, COURIER
    val isOnline: Boolean = false,
    val todayEarnings: Double = 0.0,
    val todayTasks: Int = 0,
    val activeTasks: List<DriverTask> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class DriverHomeViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(DriverHomeUiState())
    val uiState: StateFlow<DriverHomeUiState> = _uiState.asStateFlow()

    init {
        loadDriverData()
    }

    private fun loadDriverData() {
        viewModelScope.launch {
            _uiState.value = DriverHomeUiState(
                driverName = "Mehmet Şoför",
                driverType = "TAXI",
                isOnline = true,
                todayEarnings = 345.0,
                todayTasks = 8,
                activeTasks = listOf(
                    DriverTask(
                        id = "1",
                        type = "TAXI",
                        customerName = "Ahmet Yılmaz",
                        customerPhone = "+90500123",
                        pickupAddress = "Atatürk Mah. 123 Sok.",
                        dropAddress = "Cumhuriyet Mah. 456 Sok.",
                        distance = 3.2,
                        estimatedFare = 45.0,
                        status = "PENDING"
                    )
                )
            )
        }
    }

    fun toggleOnline(isOnline: Boolean) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isOnline = isOnline)
            if (isOnline) {
                // Start location updates
            } else {
                // Stop location updates
                _uiState.value = _uiState.value.copy(activeTasks = emptyList())
            }
        }
    }

    fun acceptTask(taskId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                activeTasks = _uiState.value.activeTasks.map {
                    if (it.id == taskId) it.copy(status = "ACCEPTED") else it
                }
            )
        }
    }

    fun rejectTask(taskId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                activeTasks = _uiState.value.activeTasks.filter { it.id != taskId }
            )
        }
    }
}
