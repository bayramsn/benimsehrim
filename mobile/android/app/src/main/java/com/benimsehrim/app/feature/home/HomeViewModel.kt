package com.benimsehrim.app.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.data.TokenManager
import com.benimsehrim.app.core.model.Campaign
import com.benimsehrim.app.core.model.Category
import com.benimsehrim.app.core.model.Store
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val userName: String? = null,
    val cityName: String? = "Kırşehir",
    val cartItemCount: Int = 2,
    val categories: List<Category> = emptyList(),
    val campaigns: List<Campaign> = emptyList(),
    val popularStores: List<Store> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val apiService: ApiService,
    private val tokenManager: TokenManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadUserInfo()
        loadData()
    }

    private fun loadUserInfo() {
        viewModelScope.launch {
            tokenManager.userName.collect { name ->
                _uiState.update { it.copy(userName = name ?: "Misafir") }
            }
        }
    }

    private fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                // API Calls
                val categoriesDeferred = apiService.getCategories()
                val campaignsDeferred = apiService.getCampaigns()
                val storesDeferred = apiService.getStores(limit = 5) // Popular stores

                if (categoriesDeferred.isSuccessful && campaignsDeferred.isSuccessful && storesDeferred.isSuccessful) {
                    val categories = categoriesDeferred.body() ?: getDefaultCategories()
                    val campaigns = campaignsDeferred.body() ?: getMockCampaigns()
                    val stores = storesDeferred.body()?.data ?: getMockStores()

                    _uiState.update { 
                        it.copy(
                            categories = categories,
                            campaigns = campaigns,
                            popularStores = stores,
                            isLoading = false
                        ) 
                    }
                } else {
                    // Fallback to mock
                    throw Exception("API Error")
                }
            } catch (e: Exception) {
                // Fallback to mocks on error
                e.printStackTrace()
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        categories = getDefaultCategories(),
                        campaigns = getMockCampaigns(),
                        popularStores = getMockStores()
                    ) 
                }
            }
        }
    }

    private fun getDefaultCategories(): List<Category> {
        return listOf(
            Category("1", "Kasap", "🥩", 1),
            Category("2", "Fırın", "🍞", 2),
            Category("3", "Market", "🛒", 3),
            Category("4", "Manav", "🥬", 4),
            Category("5", "Restoran", "🍽️", 5),
            Category("6", "Cafe", "☕", 6),
            Category("7", "Eczane", "💊", 7),
            Category("8", "Kırtasiye", "📚", 8)
        )
    }

    private fun getMockCampaigns(): List<Campaign> {
        val store1 = Store(
            id = "101", name = "Ahi Kasap", rating = 4.8, reviewCount = 120, 
            minOrder = 100.0, deliveryFee = 0.0, isOpen = true,
            logoUrl = null, bannerUrl = null, distance = 1.2, deliveryTime = "30 dk", categories = emptyList()
        )
        val store2 = Store(
            id = "102", name = "Saray Pastanesi", rating = 4.5, reviewCount = 85, 
            minOrder = 50.0, deliveryFee = 15.0, isOpen = true,
            logoUrl = null, bannerUrl = null, distance = 2.5, deliveryTime = "45 dk", categories = emptyList()
        )
        
        return listOf(
            Campaign(
                id = "1", 
                type = "PERCENTAGE", 
                value = 20.0, 
                startDate = "2024-01-01",
                endDate = "2024-12-31",
                stockLimit = 100,
                remainingStock = 50,
                product = null,
                store = store1
            ),
            Campaign(
                id = "2", 
                type = "BUY_X_GET_Y", 
                value = 0.0, 
                startDate = "2024-01-01",
                endDate = "2024-12-31",
                stockLimit = 100,
                remainingStock = 50,
                product = null,
                store = store2
            )
        )
    }

    private fun getMockStores(): List<Store> {
        return listOf(
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
                minOrder = 80.0, deliveryFee = 0.0, isOpen = false,
                logoUrl = null, bannerUrl = null, distance = 3.0, deliveryTime = "40 dk", categories = emptyList()
            ),
            Store(
                id = "105", name = "Kırşehir Yöresel", rating = 4.9, reviewCount = 310, 
                minOrder = 150.0, deliveryFee = 0.0, isOpen = true,
                logoUrl = null, bannerUrl = null, distance = 1.5, deliveryTime = "35 dk", categories = emptyList()
            )
        )
    }

    fun refresh() {
        loadData()
    }

    fun toggleFavorite(storeId: String) {
        _uiState.update { currentState ->
            val updatedStores = currentState.popularStores.map { 
                if (it.id == storeId) it.copy(isFavorite = !it.isFavorite) else it 
            }
            currentState.copy(popularStores = updatedStores)
        }
    }
}
