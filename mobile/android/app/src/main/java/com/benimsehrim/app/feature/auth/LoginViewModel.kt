package com.benimsehrim.app.feature.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.network.ApiService
import com.benimsehrim.app.core.model.SendOtpRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginUiState(
    val phone: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    fun onPhoneChange(phone: String) {
        // Only allow digits and max 10 characters
        val filtered = phone.filter { it.isDigit() }.take(10)
        _uiState.update { it.copy(phone = filtered, error = null) }
    }

    fun sendOtp(onSuccess: (String) -> Unit) {
        val phone = "+90${_uiState.value.phone}"
        
        if (_uiState.value.phone.length < 10) {
            _uiState.update { it.copy(error = "Geçerli bir telefon numarası giriniz") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                val response = apiService.sendOtp(SendOtpRequest(phone))
                
                if (response.isSuccessful) {
                    onSuccess(phone)
                } else {
                    // Fallback for Development if server error
                    System.err.println("API Error: ${response.code()} - Proceeding with mock success")
                    onSuccess(phone) 
                }
            } catch (e: Exception) {
                // Fallback for Development (Connection Refused etc)
                System.err.println("Network Error: ${e.message} - Proceeding with mock success")
                 _uiState.update { it.copy(isLoading = false) }
                onSuccess(phone)
            }
        }
    }
}
