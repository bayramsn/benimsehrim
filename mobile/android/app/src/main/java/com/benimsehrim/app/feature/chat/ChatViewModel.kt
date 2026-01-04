package com.benimsehrim.app.feature.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.benimsehrim.app.core.model.Message
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class ChatUiState(
    val messages: List<Message> = emptyList(),
    val messageInput: String = "",
    val partnerName: String = "Kurye Ahmet",
    val isLoading: Boolean = false
)

@HiltViewModel
class ChatViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    init {
        loadMockMessages()
    }

    private fun loadMockMessages() {
        val mockMessages = listOf(
            Message(UUID.randomUUID().toString(), "driver", "Kurye Ahmet", "Merhaba, siparişiniz yolda.", false, "10:30"),
            Message(UUID.randomUUID().toString(), "me", "Ben", "Teşekkürler, kapıda ödeme olacak mı?", true, "10:31"),
            Message(UUID.randomUUID().toString(), "driver", "Kurye Ahmet", "Evet efendim, pos cihazı getiriyorum.", false, "10:32")
        )
        _uiState.update { it.copy(messages = mockMessages) }
    }

    fun onMessageChanged(text: String) {
        _uiState.update { it.copy(messageInput = text) }
    }

    fun sendMessage() {
        if (_uiState.value.messageInput.isBlank()) return

        val newMessage = Message(
            id = UUID.randomUUID().toString(),
            senderId = "me",
            senderName = "Ben",
            content = _uiState.value.messageInput,
            isMine = true,
            createdAt = "Şimdi"
        )

        _uiState.update { 
            it.copy(
                messages = it.messages + newMessage,
                messageInput = ""
            ) 
        }

        // Mock Reply
        viewModelScope.launch {
            // Simulate delay only if this was real, but here instant is fine or use delay
        }
    }
}
