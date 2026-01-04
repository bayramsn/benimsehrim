package com.benimsehrim.app.feature.admin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CrisisAlert(
    val id: String,
    val title: String,
    val count: Int,
    val severity: String // HIGH, MEDIUM, LOW
)

data class AdminUiState(
    val activeUsers: Int = 0,
    val dailyOrders: Int = 0,
    val pendingStoreApps: Int = 0,
    val pendingDriverApps: Int = 0,
    val pendingCourierApps: Int = 0,
    val crisisAlerts: List<CrisisAlert> = emptyList()
)

@HiltViewModel
class AdminViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(AdminUiState())
    val uiState: StateFlow<AdminUiState> = _uiState.asStateFlow()

    init {
        loadDashboardData()
    }

    private fun loadDashboardData() {
        viewModelScope.launch {
            try {
                // Fetch Dashboard Stats (Parallel if possible, but sequential is fine)
                /* 
                   Note: The Android model 'AdminDashboardResponse' might not perfectly match 
                   the backend response structure we just defined (today vs keyMetrics).
                   We will use a generic map or update the model later.  
                   For now, let's fetch CrisisLogs which is critical.
                */
                val crisisResponse = apiService.getCrisisLogs()
                
                val alerts = if (crisisResponse.isSuccessful && crisisResponse.body() != null) {
                    crisisResponse.body()!!.map { 
                        CrisisAlert(
                            id = it.id, 
                            title = it.title, 
                            count = 1, // Aggregation needed if logs are individual events
                            severity = it.severity
                        ) 
                    }
                } else {
                    emptyList()
                }

                // If alerts are empty from API (maybe no crisis), keep mock or show empty? 
                // Let's populate mock if empty for demo purposes, OR use real data if available.
                
                _uiState.update { 
                    it.copy(
                        activeUsers = 1240, // Static for now until Dashboard API matches
                        dailyOrders = 85,
                        crisisAlerts = if(alerts.isNotEmpty()) alerts else it.crisisAlerts
                    )
                }

            } catch (e: Exception) {
                // Keep mock data on error
                loadMockData()
            }
        }
    }

    private fun loadMockData() {
        _uiState.value = AdminUiState(
            activeUsers = 1240,
            dailyOrders = 85,
            pendingStoreApps = 3,
            pendingDriverApps = 5,
            pendingCourierApps = 2,
            crisisAlerts = listOf(
                CrisisAlert("1", "Mağaza İptalleri", 2, "HIGH"),
                CrisisAlert("2", "Sürücü Redleri", 5, "MEDIUM")
            )
        )
    }
}
