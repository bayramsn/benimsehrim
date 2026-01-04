package com.benimsehrim.app.feature.driver

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DriverUiState(
    val isReady: Boolean = false, // !isBusy
    val isOnline: Boolean = false, // Online/Offline
    val dailyEarnings: Double = 0.0,
    val dailyRideCount: Int = 0,
    val dailyGoalTotal: Int = 10,
    val isInRestMode: Boolean = false
)

@HiltViewModel
class DriverViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(DriverUiState())
    val uiState: StateFlow<DriverUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        viewModelScope.launch {
            try {
                // Currently no dedicated driver dashboard endpoint, using `getMe`
                val response = apiService.getMe()
                if (response.isSuccessful && response.body() != null) {
                    val user = response.body()!!
                     user.driver?.let { driver ->
                         _uiState.update { 
                             it.copy(
                                 isOnline = false, // Mapping needed from driver object but not in User.Driver model yet fully
                                 isReady = !driver.isBusy,
                                 dailyEarnings = driver.usageScore * 10, // Placeholder
                                 dailyGoalTotal = driver.dailyGoal
                             )
                         }
                     }
                }
            } catch (e: Exception) {
                loadMockData()
            }
        }
    }

    private fun loadMockData() {
        _uiState.update { 
            it.copy(
                isOnline = false,
                isReady = false,
                dailyEarnings = 1250.0,
                dailyRideCount = 8
            )
        }
    }

    fun toggleOnline(online: Boolean) {
        viewModelScope.launch {
            _uiState.update { it.copy(isOnline = online) }
            if (!online) {
               _uiState.update { it.copy(isReady = false) }
            } else {
                _uiState.update { it.copy(isReady = true) }
            }
            
            try {
                // Assuming lat/lng 0 for now as we don't have location service access here easily
                apiService.updateDriverStatus(mapOf("isOnline" to online, "lat" to 0.0, "lng" to 0.0))
            } catch (e: Exception) { }
        }
    }
    
    fun toggleRestMode() {
        viewModelScope.launch {
             val newState = !_uiState.value.isInRestMode
             _uiState.update { it.copy(isInRestMode = newState) }
             
             try {
                 val duration = if(newState) 30 else 0
                 apiService.toggleRestMode(mapOf("duration" to duration))
             } catch (e: Exception) { }
        }
    }
}
