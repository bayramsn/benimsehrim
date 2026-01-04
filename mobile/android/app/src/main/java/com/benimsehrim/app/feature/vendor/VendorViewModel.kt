package com.benimsehrim.app.feature.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VendorUiState(
    val isReady: Boolean = false, // !isBusy
    val isStoreOpen: Boolean = true,
    val dailyRevenue: Double = 0.0,
    val dailyOrders: Int = 0,
    val busyAutoMode: Boolean = true
)

@HiltViewModel
class VendorViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(VendorUiState())
    val uiState: StateFlow<VendorUiState> = _uiState.asStateFlow()
    private var storeId: String? = null

    init {
        loadData()
    }

    private fun loadData() {
        viewModelScope.launch {
            try {
                // Fetch stats and operational state
                val response = apiService.getVendorDashboard() // Not implemented in backend yet, but placeholder exists
                if (response.isSuccessful && response.body() != null) {
                    val store = response.body()!!
                    storeId = store.id
                    _uiState.update { 
                        it.copy(
                            isReady = !store.isBusy, // ready = !busy
                            isStoreOpen = store.isOpen,
                            // These fields need to be in the response, currently relying on shared models
                           // which might not perfectly match the stats object yet.
                           // For now, we trust the model update.
                           dailyRevenue = store.usageScore * 100, // Placeholder mapping
                           busyAutoMode = store.busyAutoMode
                        )
                    }
                }
            } catch (e: Exception) {
                // Fallback to mock
                loadMockData()
            }
        }
    }

    private fun loadMockData() {
        _uiState.update { 
            it.copy(
                isReady = true,
                dailyRevenue = 4500.0,
                dailyOrders = 12
            )
        }
    }

    fun toggleReady(ready: Boolean) {
        viewModelScope.launch {
            _uiState.update { it.copy(isReady = ready) }
            storeId?.let { id ->
                try {
                     apiService.updateStoreBusy(id, mapOf("isBusy" to !ready))
                } catch (e: Exception) { }
            }
        }
    }
    
    fun toggleStoreOpen(open: Boolean) {
        viewModelScope.launch {
            _uiState.update { it.copy(isStoreOpen = open) }
            storeId?.let { id ->
                try {
                    apiService.updateStoreStatus(id, mapOf("isOpen" to open))
                } catch (e: Exception) { }
            }
        }
    }
}
