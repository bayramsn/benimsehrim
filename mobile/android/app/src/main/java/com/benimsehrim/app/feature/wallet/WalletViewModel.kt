package com.benimsehrim.app.feature.wallet

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject

data class WalletTransaction(
    val id: String,
    val title: String,
    val amount: Double,
    val type: String, // CREDIT, DEBIT
    val date: String
)

data class WalletUiState(
    val balance: Double = 1250.0,
    val transactions: List<WalletTransaction> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class WalletViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(WalletUiState())
    val uiState: StateFlow<WalletUiState> = _uiState.asStateFlow()

    init {
        loadTransactions()
    }

    private fun loadTransactions() {
        val mockData = listOf(
            WalletTransaction("1", "Kırşehir Market", 350.0, "DEBIT", "10 Kas 14:30"),
            WalletTransaction("2", "Taksi Yolculuğu", 120.0, "DEBIT", "09 Kas 18:45"),
            WalletTransaction("3", "Kredi Kartı Yükleme", 1000.0, "CREDIT", "01 Kas 09:00"),
            WalletTransaction("4", "Ahi Kasap", 450.0, "DEBIT", "28 Eki 12:15")
        )
        _uiState.update { it.copy(transactions = mockData) }
    }
}
