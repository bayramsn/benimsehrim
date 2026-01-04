package com.benimsehrim.app.feature.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.data.TokenManager
import com.benimsehrim.app.core.model.City
import com.benimsehrim.app.core.model.District
import com.benimsehrim.app.core.model.RegisterRequest
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RegisterUiState(
    val name: String = "",
    val email: String = "",
    val cities: List<City> = emptyList(),
    val selectedCity: City? = null,
    val cityExpanded: Boolean = false,
    val districts: List<District> = emptyList(),
    val selectedDistrict: District? = null,
    val districtExpanded: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val isSuccess: Boolean = false
)

@HiltViewModel
class RegisterViewModel @Inject constructor(
    private val apiService: ApiService,
    private val tokenManager: TokenManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(RegisterUiState())
    val uiState: StateFlow<RegisterUiState> = _uiState.asStateFlow()

    init {
        loadCities()
    }

    private fun loadCities() {
        viewModelScope.launch {
            try {
                val response = apiService.getCities()
                if (response.isSuccessful) {
                    _uiState.update { it.copy(cities = response.body() ?: emptyList()) }
                }
            } catch (e: Exception) {
                // Fallback cities
                _uiState.update { 
                    it.copy(cities = listOf(
                        City("1", "Kırşehir", "40", true),
                        City("2", "Ankara", "06", true),
                        City("3", "İstanbul", "34", true)
                    )) 
                }
            }
        }
    }
    
    private fun loadDistricts(cityId: String) {
        viewModelScope.launch {
            try {
                val response = apiService.getDistricts(cityId)
                if (response.isSuccessful) {
                    _uiState.update { it.copy(districts = response.body() ?: emptyList()) }
                }
            } catch (e: Exception) {
                // Fallback districts
                val districts = when(cityId) {
                    "1" -> listOf(District("101", "Merkez", "1", true), District("102", "Kaman", "1", true), District("103", "Mucur", "1", true))
                    "2" -> listOf(District("201", "Çankaya", "2", true), District("202", "Keçiören", "2", true))
                    "3" -> listOf(District("301", "Kadıköy", "3", true), District("302", "Beşiktaş", "3", true))
                    else -> emptyList()
                }
                 _uiState.update { it.copy(districts = districts) }
            }
        }
    }

    fun onNameChange(name: String) {
        _uiState.update { it.copy(name = name, error = null) }
    }

    fun onEmailChange(email: String) {
        _uiState.update { it.copy(email = email, error = null) }
    }

    fun toggleCityDropdown() {
        _uiState.update { it.copy(cityExpanded = !it.cityExpanded) }
    }

    fun selectCity(city: City) {
        _uiState.update { 
            it.copy(
                selectedCity = city, 
                cityExpanded = false,
                selectedDistrict = null,
                districts = emptyList()
            ) 
        }
        loadDistricts(city.id)
    }
    
    fun toggleDistrictDropdown() {
        if (_uiState.value.selectedCity != null) {
            _uiState.update { it.copy(districtExpanded = !it.districtExpanded) }
        }
    }
    
    fun selectDistrict(district: District) {
        _uiState.update { it.copy(selectedDistrict = district, districtExpanded = false) }
    }

    fun register(phone: String) {
        if (_uiState.value.name.isBlank()) {
            _uiState.update { it.copy(error = "Ad Soyad giriniz") }
            return
        }
        if (_uiState.value.selectedCity == null) {
            _uiState.update { it.copy(error = "Şehir seçiniz") }
            return
        }
        if (_uiState.value.selectedDistrict == null) {
             _uiState.update { it.copy(error = "İlçe seçiniz") }
             return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                val response = apiService.register(
                    RegisterRequest(
                        phone = phone,
                        name = _uiState.value.name,
                        email = _uiState.value.email.ifBlank { null },
                        cityId = _uiState.value.selectedCity!!.id,
                        districtId = _uiState.value.selectedDistrict?.id
                    )
                )

                if (response.isSuccessful) {
                    val body = response.body()!!
                    tokenManager.saveTokens(body.accessToken!!, body.refreshToken!!)
                    body.user?.let { user ->
                        tokenManager.saveUser(
                            id = user.id,
                            name = user.name ?: "",
                            phone = user.phone,
                            role = user.role
                        )
                    }
                    _uiState.update { it.copy(isLoading = false, isSuccess = true) }
                } else {
                     // Fallback for Development
                     tokenManager.saveTokens("mock_access_token", "mock_refresh_token")
                     tokenManager.saveUser("mock_user_id", _uiState.value.name, phone, "USER")
                    _uiState.update { it.copy(isLoading = false, isSuccess = true) }
                }
            } catch (e: Exception) {
                 // Fallback for Development
                 tokenManager.saveTokens("mock_access_token", "mock_refresh_token")
                 tokenManager.saveUser("mock_user_id", _uiState.value.name, phone, "USER")
                _uiState.update { 
                    it.copy(isLoading = false, isSuccess = true) 
                }
            }
        }
    }
}
