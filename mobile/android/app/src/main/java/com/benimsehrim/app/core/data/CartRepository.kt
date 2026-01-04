package com.benimsehrim.app.core.data

import com.benimsehrim.app.core.model.Product
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CartRepository @Inject constructor() {
    // Product -> Quantity
    private val _cartItems = MutableStateFlow<Map<Product, Int>>(emptyMap())
    val cartItems: StateFlow<Map<Product, Int>> = _cartItems.asStateFlow()

    fun addToCart(product: Product) {
        _cartItems.update { currentItems ->
            // Find existing product with same ID to ensure consistency
            val existingProduct = currentItems.keys.find { it.id == product.id } ?: product
            val count = currentItems[existingProduct] ?: 0
            currentItems + (existingProduct to count + 1)
        }
    }

    fun removeFromCart(product: Product) {
        _cartItems.update { currentItems ->
            val existingProduct = currentItems.keys.find { it.id == product.id } ?: product
            val count = currentItems[existingProduct] ?: 0
            if (count > 1) {
                currentItems + (existingProduct to count - 1)
            } else {
                currentItems - existingProduct
            }
        }
    }
    
    fun clearCart() {
        _cartItems.value = emptyMap()
    }
    
    fun getCartTotal(): Double {
        return _cartItems.value.entries.sumOf { (product, count) -> product.price * count }
    }
    
    fun getItemCount(): Int {
        return _cartItems.value.values.sum()
    }
}
