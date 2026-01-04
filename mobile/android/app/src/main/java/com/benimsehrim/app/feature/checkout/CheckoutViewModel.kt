package com.benimsehrim.app.feature.checkout

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.data.CartRepository
import com.benimsehrim.app.core.data.MockOrderRepository
import com.benimsehrim.app.core.model.Address
import com.benimsehrim.app.core.model.Order
import com.benimsehrim.app.core.model.Store
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import javax.inject.Inject

data class CheckoutUiState(
    val addresses: List<Address> = emptyList(),
    val selectedAddress: Address? = null,
    val paymentMethod: String = "Nakit", // Nakit, Kredi Kartı
    val note: String = "",
    val isLoading: Boolean = false,
    val isOrderCreated: Boolean = false,
    val totalAmount: Double = 0.0,
    val couponCode: String = "",
    val discountAmount: Double = 0.0,
    val couponMessage: String? = null,
    val isCouponApplied: Boolean = false
)

@HiltViewModel
class CheckoutViewModel @Inject constructor(
    private val cartRepository: CartRepository,
    private val mockOrderRepository: MockOrderRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CheckoutUiState())
    val uiState: StateFlow<CheckoutUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        // Mock Addresses
        val mockAddresses = listOf(
            Address("1", "Ev", "Kuşdili Mah. 123. Sok. No:5, Kırşehir", 0.0, 0.0, "Zil çalışmıyor", true),
            Address("2", "İş", "Organize Sanayi Bölgesi, Kırşehir", 0.0, 0.0, "Güvenliğe bırakın", false)
        )
        
         viewModelScope.launch {
            cartRepository.cartItems.collect { items ->
                 val total = cartRepository.getCartTotal()
                 _uiState.update { 
                    it.copy(
                        addresses = mockAddresses,
                        selectedAddress = it.selectedAddress ?: mockAddresses.firstOrNull(),
                        totalAmount = total
                    )
                }
            }
        }
    }

    fun selectAddress(address: Address) {
        _uiState.update { it.copy(selectedAddress = address) }
    }

    fun selectPaymentMethod(method: String) {
        _uiState.update { it.copy(paymentMethod = method) }
    }
    
    fun updateNote(note: String) {
        _uiState.update { it.copy(note = note) }
    }
    
    fun onCouponCodeChanged(code: String) {
        _uiState.update { it.copy(couponCode = code) }
    }

    fun applyCoupon() {
        val code = _uiState.value.couponCode
        if (code.equals("INDIRIM50", ignoreCase = true)) {
             _uiState.update { it.copy(discountAmount = 50.0, couponMessage = "50₺ indirim uygulandı!", isCouponApplied = true) }
        } else if (code.equals("YUZDE10", ignoreCase = true)) {
             val discount = _uiState.value.totalAmount * 0.10
             _uiState.update { it.copy(discountAmount = discount, couponMessage = "%10 indirim uygulandı!", isCouponApplied = true) }
        } else {
             _uiState.update { it.copy(couponMessage = "Geçersiz kupon kodu", isCouponApplied = false, discountAmount = 0.0) }
        }
    }
    
    fun removeCoupon() {
        _uiState.update { it.copy(couponCode = "", discountAmount = 0.0, couponMessage = null, isCouponApplied = false) }
    }

    fun completeOrder() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            delay(1500) // Mock API call logic
            
            // Create Mock Order
            val finalTotal = (_uiState.value.totalAmount - _uiState.value.discountAmount).coerceAtLeast(0.0)
            
            val newOrder = Order(
                id = UUID.randomUUID().toString(),
                orderNo = "S-${(100000..999999).random()}",
                store = Store(
                    id = "1", 
                    name = "Kırşehir Market", 
                    logoUrl = null, 
                    bannerUrl = null, 
                    rating = 4.8, 
                    reviewCount = 120, 
                    isOpen = true,
                    distance = 1.5, 
                    deliveryTime = "25-30 dk", 
                    minOrder = 100.0, 
                    deliveryFee = 0.0, 
                    categories = null
                ),
                status = "PREPARING",
                total = finalTotal,
                itemCount = cartRepository.getItemCount(),
                createdAt = SimpleDateFormat("dd MMM HH:mm", Locale("tr")).format(Date())
            )
            
            mockOrderRepository.addOrder(newOrder)
            cartRepository.clearCart()
            
            _uiState.update { it.copy(isLoading = false, isOrderCreated = true) }
        }
    }
}
