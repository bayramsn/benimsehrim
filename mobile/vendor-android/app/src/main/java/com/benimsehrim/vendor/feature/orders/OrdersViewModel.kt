package com.benimsehrim.vendor.feature.orders

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VendorOrder(
    val id: String,
    val orderNo: String,
    val customerName: String,
    val customerPhone: String,
    val total: Double,
    val itemCount: Int,
    val status: String,
    val timeAgo: String,
    val items: List<OrderItem> = emptyList()
)

data class OrderItem(
    val name: String,
    val quantity: Int,
    val price: Double
)

data class OrdersUiState(
    val orders: List<VendorOrder> = emptyList(),
    val isLoading: Boolean = false,
    val currentFilter: String = "ALL"
)

@HiltViewModel
class OrdersViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(OrdersUiState())
    val uiState: StateFlow<OrdersUiState> = _uiState.asStateFlow()

    private var allOrders: List<VendorOrder> = emptyList()

    init {
        loadOrders()
    }

    private fun loadOrders() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // Demo data
            allOrders = listOf(
                VendorOrder("1", "ORD-2024-001", "Ahmet Yılmaz", "+90500123", 245.0, 3, "PENDING", "2 dk önce"),
                VendorOrder("2", "ORD-2024-002", "Mehmet Demir", "+90500124", 180.0, 2, "PREPARING", "15 dk önce"),
                VendorOrder("3", "ORD-2024-003", "Ayşe Kaya", "+90500125", 320.0, 4, "READY", "25 dk önce"),
                VendorOrder("4", "ORD-2024-004", "Fatma Şahin", "+90500126", 150.0, 2, "ON_WAY", "40 dk önce"),
                VendorOrder("5", "ORD-2024-005", "Ali Özkan", "+90500127", 420.0, 5, "DELIVERED", "1 saat önce"),
            )

            _uiState.value = OrdersUiState(orders = allOrders, isLoading = false)
        }
    }

    fun filterOrders(status: String) {
        val filtered = if (status == "ALL") allOrders else allOrders.filter { it.status == status }
        _uiState.value = _uiState.value.copy(orders = filtered, currentFilter = status)
    }

    fun acceptOrder(orderId: String) {
        updateOrderStatus(orderId, "ACCEPTED")
    }

    fun startPreparing(orderId: String) {
        updateOrderStatus(orderId, "PREPARING")
    }

    fun markReady(orderId: String) {
        updateOrderStatus(orderId, "READY")
    }

    private fun updateOrderStatus(orderId: String, newStatus: String) {
        viewModelScope.launch {
            allOrders = allOrders.map {
                if (it.id == orderId) it.copy(status = newStatus) else it
            }
            filterOrders(_uiState.value.currentFilter)
        }
    }
}
