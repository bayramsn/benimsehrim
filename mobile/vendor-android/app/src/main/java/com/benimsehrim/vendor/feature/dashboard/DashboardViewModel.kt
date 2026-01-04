package com.benimsehrim.vendor.feature.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RecentOrder(
    val id: String,
    val orderNo: String,
    val customerName: String,
    val total: Double,
    val status: String
)

data class DashboardUiState(
    val storeName: String = "Mağazam",
    val isOpen: Boolean = true,
    val todayOrders: Int = 0,
    val todayRevenue: Double = 0.0,
    val pendingOrders: Int = 0,
    val recentOrders: List<RecentOrder> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class DashboardViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        loadDashboard()
    }

    private fun loadDashboard() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // Demo data
            _uiState.value = DashboardUiState(
                storeName = "Kırşehir Kasabı",
                isOpen = true,
                todayOrders = 12,
                todayRevenue = 2450.0,
                pendingOrders = 3,
                recentOrders = listOf(
                    RecentOrder("1", "ORD-2024-001", "Ahmet Yılmaz", 245.0, "PENDING"),
                    RecentOrder("2", "ORD-2024-002", "Mehmet Demir", 180.0, "PREPARING"),
                    RecentOrder("3", "ORD-2024-003", "Ayşe Kaya", 320.0, "READY"),
                ),
                isLoading = false
            )
        }
    }

    fun toggleStore(isOpen: Boolean) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isOpen = isOpen)
            // API call to update store status
        }
    }
}
