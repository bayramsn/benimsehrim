package com.benimsehrim.app.feature.cart

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.data.CartRepository
import com.benimsehrim.app.core.model.Product
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CartUiState(
    val items: Map<Product, Int> = emptyMap(),
    val totalAmount: Double = 0.0,
    val itemCount: Int = 0,
    val isLoading: Boolean = false
)

@HiltViewModel
class CartViewModel @Inject constructor(
    private val cartRepository: CartRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(CartUiState())
    val uiState: StateFlow<CartUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            cartRepository.cartItems.collect { items ->
                val total = cartRepository.getCartTotal()
                val count = cartRepository.getItemCount()
                _uiState.update { 
                    it.copy(
                        items = items,
                        totalAmount = total,
                        itemCount = count
                    )
                }
            }
        }
    }
    
    fun increaseQuantity(product: Product) {
        cartRepository.addToCart(product)
    }
    
    fun decreaseQuantity(product: Product) {
        cartRepository.removeFromCart(product)
    }
    
    fun clearCart() {
        cartRepository.clearCart()
    }
}
