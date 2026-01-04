package com.benimsehrim.app.core.data

import com.benimsehrim.app.core.model.Order
import com.benimsehrim.app.core.model.Store
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MockOrderRepository @Inject constructor() {
    private val _orders = MutableStateFlow<List<Order>>(emptyList())
    val orders: StateFlow<List<Order>> = _orders.asStateFlow()
    
    init {
        // Add some dummy history for better UX
        val historyOrder = Order(
            id = "mock-old-1",
            orderNo = "S-102030",
            store = Store(
                id = "store-1",
                name = "Kırşehir Kebapçısı",
                logoUrl = null, bannerUrl=null, rating=4.5, reviewCount=50, isOpen=true,
                distance=1.0, deliveryTime="30 dk", minOrder=100.0, deliveryFee=0.0, categories=null
            ),
            status = "DELIVERED",
            total = 250.0,
            itemCount = 3,
            createdAt = "28 Ara 14:30"
        )
        _orders.value = listOf(historyOrder)
    }

    fun addOrder(order: Order) {
        _orders.update { currentList ->
            listOf(order) + currentList // Add new order to top
        }
    }

    fun getOrders(): List<Order> {
        return _orders.value
    }
}
