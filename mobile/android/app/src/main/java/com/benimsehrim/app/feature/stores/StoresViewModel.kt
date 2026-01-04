package com.benimsehrim.app.feature.stores

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.model.Store
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class StoresUiState(
    val stores: List<Store> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class StoresViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(StoresUiState())
    val uiState: StateFlow<StoresUiState> = _uiState.asStateFlow()

    fun loadStores(categoryId: String? = null) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            try {
                // Mock Data
                _uiState.update { 
                    it.copy(
                        stores = getMockStores(categoryId),
                        isLoading = false
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        stores = getMockStores(categoryId)
                    ) 
                }
            }
        }
    }
    
    private fun getMockStores(categoryId: String?): List<Store> {
        val allStores = listOf(
            Store(
                id = "101", name = "Ahi Kasap", rating = 4.8, reviewCount = 120, 
                minOrder = 100.0, deliveryFee = 0.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 1.2, deliveryTime = "30 dk", categories = emptyList()
            ),
            Store(
                id = "102", name = "Saray Pastanesi", rating = 4.5, reviewCount = 85, 
                minOrder = 50.0, deliveryFee = 15.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 2.5, deliveryTime = "45 dk", categories = emptyList()
            ),
            Store(
                id = "103", name = "Bizim Manav", rating = 4.2, reviewCount = 45, 
                minOrder = 60.0, deliveryFee = 10.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 0.8, deliveryTime = "20 dk", categories = emptyList()
            ),
            Store(
                id = "104", name = "Keyif Cafe & Bistro", rating = 4.7, reviewCount = 200, 
                minOrder = 80.0, deliveryFee = 0.0, isOpen = false, // Kapalı
                logoUrl = null, bannerUrl = null, distance = 3.0, deliveryTime = "40 dk", categories = emptyList()
            ),
            Store(
                id = "105", name = "Kırşehir Yöresel", rating = 4.9, reviewCount = 310, 
                minOrder = 150.0, deliveryFee = 0.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 1.5, deliveryTime = "35 dk", categories = emptyList()
            ),
            Store(
                id = "106", name = "Umut Eczanesi", rating = 5.0, reviewCount = 12, 
                minOrder = 0.0, deliveryFee = 20.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 0.5, deliveryTime = "15 dk", categories = emptyList()
            ),
            Store(
                id = "107", name = "Bilgi Kırtasiye", rating = 4.0, reviewCount = 30, 
                minOrder = 40.0, deliveryFee = 12.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 1.0, deliveryTime = "25 dk", categories = emptyList()
            )
        )
        
        return if (categoryId != null) {
            if (categoryId.toIntOrNull()?.rem(2) == 0) {
                 allStores.filter { it.name.contains("a") }
            } else {
                 allStores
            }
        } else {
            allStores
        }
    }
}
