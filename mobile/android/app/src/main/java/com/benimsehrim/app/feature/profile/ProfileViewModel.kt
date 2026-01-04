package com.benimsehrim.app.feature.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.data.TokenManager
import com.benimsehrim.app.core.network.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileUiState(
    val name: String? = null,
    val phone: String? = null,
    val email: String? = null,
    val role: String = "USER",
    val isCourier: Boolean = false,
    val isDriver: Boolean = false,
    val userId: String? = null
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val apiService: ApiService,
    private val tokenManager: TokenManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    init {
        loadUserInfo()
    }

    private fun loadUserInfo() {
        // Load from local cache first
        viewModelScope.launch {
            tokenManager.userName.collect { name ->
                _uiState.update { it.copy(name = name) }
            }
        }
        viewModelScope.launch {
            tokenManager.userPhone.collect { phone ->
                _uiState.update { it.copy(phone = phone) }
            }
        }

        // Fetch fresh data from API
        fetchUserProfile()
    }

    private fun fetchUserProfile() {
        viewModelScope.launch {
            try {
                val response = apiService.getMe()
                if (response.isSuccessful) {
                    val user = response.body()
                    user?.let { u ->
                        _uiState.update { state ->
                            state.copy(
                                name = u.name,
                                phone = u.phone,
                                email = u.email,
                                role = u.role,
                                isCourier = u.courier != null,
                                isDriver = u.driver != null,
                                userId = u.id
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            tokenManager.clearTokens()
            _uiState.update { ProfileUiState() }
        }
    }
}
