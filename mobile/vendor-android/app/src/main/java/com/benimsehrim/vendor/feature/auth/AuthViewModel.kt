package com.benimsehrim.vendor.feature.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AuthUiState(
    val isLoading: Boolean = false,
    val isOtpSent: Boolean = false,
    val isLoggedIn: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class AuthViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    fun sendOtp(phone: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            delay(1000) // Simulate API call
            _uiState.value = _uiState.value.copy(isLoading = false, isOtpSent = true)
        }
    }

    fun verifyOtp(phone: String, otp: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            delay(1000) // Simulate API call

            if (otp == "123456") {
                _uiState.value = _uiState.value.copy(isLoading = false, isLoggedIn = true)
                _isLoggedIn.value = true
            } else {
                _uiState.value = _uiState.value.copy(isLoading = false, error = "Geçersiz kod")
            }
        }
    }

    fun resetOtp() {
        _uiState.value = AuthUiState()
    }

    fun logout() {
        _isLoggedIn.value = false
        _uiState.value = AuthUiState()
    }
}
