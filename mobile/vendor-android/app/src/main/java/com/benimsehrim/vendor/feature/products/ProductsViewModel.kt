package com.benimsehrim.vendor.feature.products

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProductsUiState(
    val products: List<Product> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class ProductsViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(ProductsUiState())
    val uiState: StateFlow<ProductsUiState> = _uiState.asStateFlow()

    init {
        loadProducts()
    }

    private fun loadProducts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // Demo data
            _uiState.value = ProductsUiState(
                products = listOf(
                    Product("1", "Dana Kıyma", "Taze çekilmiş", 280.0, 50, "kg", null, true, true),
                    Product("2", "Kuzu Pirzola", "Günlük kesim", 320.0, 30, "kg", null, true),
                    Product("3", "Biftek", "Premium kalite", 450.0, 20, "kg", null, true),
                    Product("4", "Sucuk", "Ev yapımı", 150.0, 5, "kg", null, true),
                    Product("5", "Pastırma", "Kayseri usulü", 280.0, 8, "kg", null, false),
                ),
                isLoading = false
            )
        }
    }

    fun toggleProductActive(productId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                products = _uiState.value.products.map {
                    if (it.id == productId) it.copy(isActive = !it.isActive) else it
                }
            )
        }
    }
}
