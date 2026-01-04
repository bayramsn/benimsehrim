import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageInput: String = ""
    @Published var partnerName: String = "Kurye Ahmet"
    
    init() {
        loadMockMessages()
    }
    
    func loadMockMessages() {
        self.messages = [
            Message(id: "1", senderId: "driver", senderName: "Kurye Ahmet", content: "Merhaba, siparişiniz yolda.", isMine: false, createdAt: "10:30"),
            Message(id: "2", senderId: "me", senderName: "Ben", content: "Teşekkürler, kapıda ödeme olacak mı?", isMine: true, createdAt: "10:31"),
            Message(id: "3", senderId: "driver", senderName: "Kurye Ahmet", content: "Evet efendim, pos cihazı getiriyorum.", isMine: false, createdAt: "10:32")
        ]
    }
    
    func sendMessage() {
        guard !messageInput.isEmpty else { return }
        let newMessage = Message(id: UUID().uuidString, senderId: "me", senderName: "Ben", content: messageInput, isMine: true, createdAt: "Şimdi")
        messages.append(newMessage)
        messageInput = ""
    }
}
