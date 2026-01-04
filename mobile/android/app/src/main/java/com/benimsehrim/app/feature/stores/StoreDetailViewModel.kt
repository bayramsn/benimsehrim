package com.benimsehrim.app.feature.stores

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.data.CartRepository
import com.benimsehrim.app.core.model.Product
import com.benimsehrim.app.core.model.StoreDetail
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class StoreDetailUiState(
    val isLoading: Boolean = false,
    val store: StoreDetail? = null,
    val error: String? = null,
    val cartTotal: Double = 0.0,
    val cartItemCount: Int = 0,
    val cartItems: Map<Product, Int> = emptyMap()
)

@HiltViewModel
class StoreDetailViewModel @Inject constructor(
    private val apiService: ApiService,
    private val cartRepository: CartRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(StoreDetailUiState())
    val uiState: StateFlow<StoreDetailUiState> = _uiState.asStateFlow()

    init {
        // Observe cart changes
        viewModelScope.launch {
            cartRepository.cartItems.collect { items ->
                _uiState.update { 
                    it.copy(
                        cartItems = items,
                        cartItemCount = cartRepository.getItemCount(),
                        cartTotal = cartRepository.getCartTotal()
                    )
                }
            }
        }
    }

    fun loadStore(storeId: String) {
        _uiState.update { it.copy(isLoading = true) }
        viewModelScope.launch {
            try {
                // Try Backend Call
                val response = apiService.getStore(storeId)
                if (response.isSuccessful && response.body() != null) {
                    _uiState.update { it.copy(
                        isLoading = false,
                        store = response.body()
                    )}
                    return@launch
                }
            } catch (e: Exception) {
                // If backend fails, fallback to Mock Data
            }
            
            // Mock Fallback
            val mockProducts = listOf(
                Product(
                    id = "1", 
                    name = "Dana Kıyma", 
                    description = "1 kg, %100 Dana", 
                    price = 350.0, 
                    stock = 50,
                    unit = "kg",
                    images = listOf("https://via.placeholder.com/150"), 
                    isActive = true, 
                    campaigns = null
                ),
                Product(
                    id = "2", 
                    name = "Kuzu Pirzola", 
                    description = "1 kg, Taze", 
                    price = 450.0, 
                    stock = 30,
                    unit = "kg",
                    images = listOf("https://via.placeholder.com/150"), 
                    isActive = true, 
                    campaigns = null
                ),
                Product(
                    id = "3", 
                    name = "Kasap Köfte", 
                    description = "500 gr, Özel Baharatlı", 
                    price = 180.0,
                    discountPrice = 150.0,
                    stock = 100,
                    unit = "pkt",
                    images = listOf("https://via.placeholder.com/150"), 
                    isActive = true, 
                    campaigns = null
                ),
                Product(
                    id = "4", 
                    name = "Sucuk", 
                    description = "Geleneksel, Kangal", 
                    price = 220.0, 
                    stock = 50,
                    unit = "kg",
                    images = listOf("https://via.placeholder.com/150"), 
                    isActive = true, 
                    campaigns = null
                )
            )

            val mockStore = StoreDetail(
                id = storeId,
                name = if(storeId == "1") "Ahi Kasap" else "Mağaza $storeId",
                description = "Şehrin en taze et ve et ürünleri.",
                logoUrl = null,
                bannerUrl = null,
                address = "Terme Cad. No:5, Kırşehir",
                phone = "0386 213 00 00",
                rating = 4.8,
                reviewCount = 120,
                isOpen = true,
                openTime = "09:00",
                closeTime = "21:00",
                paymentTypes = listOf("Nakit", "Kredi Kartı"),
                minOrder = 100.0,
                deliveryFee = 0.0,
                products = mockProducts,
                campaigns = emptyList()
            )
            
            _uiState.update { it.copy(
                isLoading = false,
                store = mockStore
            )}
        }
    }

    fun addToCart(product: Product) {
        cartRepository.addToCart(product)
    }

    fun removeFromCart(product: Product) {
        cartRepository.removeFromCart(product)
    }
    
    fun getCartQuantity(productId: String): Int {
        return _uiState.value.cartItems.entries
            .find { it.key.id == productId }?.value ?: 0
    }
}
