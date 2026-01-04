import Foundation
import Combine

// MARK: - Support/Ticket System (Destek Sistemi)
class SupportManager: ObservableObject {
    static let shared = SupportManager()
    
    @Published var tickets: [SupportTicket] = []
    @Published var faqItems: [FAQItem] = []
    @Published var isLoading = false
    
    private let ticketsKey = "support_tickets"
    
    init() {
        loadTickets()
        loadFAQ()
    }
    
    // MARK: - Create Ticket
    func createTicket(
        type: TicketType,
        subject: String,
        description: String,
        orderId: String? = nil,
        rideId: String? = nil,
        attachments: [String] = []
    ) -> SupportTicket {
        let ticket = SupportTicket(
            id: UUID().uuidString,
            ticketNo: generateTicketNumber(),
            userId: AuthManager.shared.currentUser?.id ?? "",
            type: type,
            subject: subject,
            description: description,
            status: .open,
            priority: determinePriority(type: type),
            orderId: orderId,
            rideId: rideId,
            attachments: attachments,
            messages: [],
            createdAt: Date(),
            updatedAt: Date(),
            resolvedAt: nil,
            resolvedBy: nil,
            rating: nil,
            feedback: nil
        )
        
        tickets.insert(ticket, at: 0)
        saveTickets()
        
        // TODO: Sync with backend
        // NetworkManager.shared.createTicket(ticket)
        
        return ticket
    }
    
    // MARK: - Add Message to Ticket
    func addMessage(ticketId: String, content: String, isFromSupport: Bool = false) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketId }) else { return }
        
        let message = TicketMessage(
            id: UUID().uuidString,
            senderId: isFromSupport ? "support" : (AuthManager.shared.currentUser?.id ?? ""),
            senderName: isFromSupport ? "Destek Ekibi" : (AuthManager.shared.currentUser?.name ?? "Kullanıcı"),
            content: content,
            isFromSupport: isFromSupport,
            attachments: [],
            createdAt: Date()
        )
        
        tickets[index].messages.append(message)
        tickets[index].updatedAt = Date()
        saveTickets()
    }
    
    // MARK: - Update Ticket Status
    func updateTicketStatus(ticketId: String, status: TicketStatus) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketId }) else { return }
        
        tickets[index].status = status
        tickets[index].updatedAt = Date()
        
        if status == .resolved {
            tickets[index].resolvedAt = Date()
        }
        
        saveTickets()
    }
    
    // MARK: - Rate Support
    func rateTicket(ticketId: String, rating: Int, feedback: String?) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketId }) else { return }
        
        tickets[index].rating = rating
        tickets[index].feedback = feedback
        saveTickets()
    }
    
    // MARK: - Get Tickets
    var openTickets: [SupportTicket] {
        tickets.filter { $0.status == .open || $0.status == .inProgress }
    }
    
    var closedTickets: [SupportTicket] {
        tickets.filter { $0.status == .resolved || $0.status == .closed }
    }
    
    // MARK: - Helper Methods
    private func generateTicketNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let dateStr = dateFormatter.string(from: Date())
        let random = String(format: "%04d", Int.random(in: 1000...9999))
        return "TKT-\(dateStr)-\(random)"
    }
    
    private func determinePriority(type: TicketType) -> TicketPriority {
        switch type {
        case .payment, .safety:
            return .high
        case .orderIssue, .deliveryIssue:
            return .medium
        case .accountIssue, .appBug:
            return .medium
        case .suggestion, .other:
            return .low
        }
    }
    
    // MARK: - Persistence
    private func saveTickets() {
        if let data = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(data, forKey: ticketsKey)
        }
    }
    
    private func loadTickets() {
        if let data = UserDefaults.standard.data(forKey: ticketsKey),
           let saved = try? JSONDecoder().decode([SupportTicket].self, from: data) {
            tickets = saved
        }
    }
    
    // MARK: - FAQ
    private func loadFAQ() {
        faqItems = [
            FAQItem(
                id: "1",
                category: "Sipariş",
                question: "Siparişimi nasıl iptal edebilirim?",
                answer: "Sipariş detay sayfasından 'İptal Et' butonuna tıklayarak siparişinizi iptal edebilirsiniz. Hazırlanmaya başlanmış siparişler iptal edilemez."
            ),
            FAQItem(
                id: "2",
                category: "Sipariş",
                question: "Siparişim ne zaman gelir?",
                answer: "Tahmini teslimat süresi sipariş detay sayfasında gösterilmektedir. Yoğun saatlerde gecikmeler yaşanabilir."
            ),
            FAQItem(
                id: "3",
                category: "Ödeme",
                question: "Hangi ödeme yöntemlerini kullanabilirim?",
                answer: "Nakit, kredi kartı ve uygulama cüzdanı ile ödeme yapabilirsiniz."
            ),
            FAQItem(
                id: "4",
                category: "Ödeme",
                question: "İade nasıl yapılır?",
                answer: "İptal edilen siparişlerde ödemeniz otomatik olarak iade edilir. İade süresi ödeme yöntemine göre 1-7 iş günü arasında değişir."
            ),
            FAQItem(
                id: "5",
                category: "Taksi",
                question: "Taksi ücreti nasıl hesaplanır?",
                answer: "Taksi ücreti mesafe ve süreye göre hesaplanır. Tahmini ücret çağrı öncesinde gösterilir."
            ),
            FAQItem(
                id: "6",
                category: "Taksi",
                question: "Taksi çağrımı iptal edebilir miyim?",
                answer: "Şoför kabul etmeden önce ücretsiz iptal edebilirsiniz. Şoför yola çıktıktan sonra iptal ücreti uygulanabilir."
            ),
            FAQItem(
                id: "7",
                category: "Kurye",
                question: "Kurye ile ne gönderebilirim?",
                answer: "Yasal olmayan, tehlikeli ve bozulabilir ürünler hariç her türlü paketi gönderebilirsiniz."
            ),
            FAQItem(
                id: "8",
                category: "Hesap",
                question: "Şifremi unuttum, ne yapmalıyım?",
                answer: "Giriş sayfasında 'Şifremi Unuttum' seçeneğini kullanarak telefon numaranıza doğrulama kodu gönderebilirsiniz."
            ),
            FAQItem(
                id: "9",
                category: "Hesap",
                question: "Hesabımı nasıl silerim?",
                answer: "Profil > Ayarlar > Hesabı Sil bölümünden hesabınızı kalıcı olarak silebilirsiniz. Bu işlem geri alınamaz."
            ),
            FAQItem(
                id: "10",
                category: "Uygulama",
                question: "Uygulama çalışmıyor, ne yapmalıyım?",
                answer: "Uygulamayı kapatıp tekrar açın. Sorun devam ederse uygulamayı güncelleyin veya yeniden yükleyin."
            )
        ]
    }
}

// MARK: - Support Models
struct SupportTicket: Codable, Identifiable {
    let id: String
    let ticketNo: String
    let userId: String
    let type: TicketType
    let subject: String
    let description: String
    var status: TicketStatus
    let priority: TicketPriority
    let orderId: String?
    let rideId: String?
    let attachments: [String]
    var messages: [TicketMessage]
    let createdAt: Date
    var updatedAt: Date
    var resolvedAt: Date?
    var resolvedBy: String?
    var rating: Int?
    var feedback: String?
}

struct TicketMessage: Codable, Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let content: String
    let isFromSupport: Bool
    let attachments: [String]
    let createdAt: Date
}

enum TicketType: String, Codable, CaseIterable {
    case orderIssue = "order_issue"
    case deliveryIssue = "delivery_issue"
    case payment = "payment"
    case accountIssue = "account_issue"
    case appBug = "app_bug"
    case safety = "safety"
    case suggestion = "suggestion"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .orderIssue: return "Sipariş Sorunu"
        case .deliveryIssue: return "Teslimat Sorunu"
        case .payment: return "Ödeme Sorunu"
        case .accountIssue: return "Hesap Sorunu"
        case .appBug: return "Uygulama Hatası"
        case .safety: return "Güvenlik"
        case .suggestion: return "Öneri"
        case .other: return "Diğer"
        }
    }
    
    var icon: String {
        switch self {
        case .orderIssue: return "bag.fill"
        case .deliveryIssue: return "shippingbox.fill"
        case .payment: return "creditcard.fill"
        case .accountIssue: return "person.fill"
        case .appBug: return "ladybug.fill"
        case .safety: return "shield.fill"
        case .suggestion: return "lightbulb.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum TicketStatus: String, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case waitingResponse = "waiting_response"
    case resolved = "resolved"
    case closed = "closed"
    
    var displayName: String {
        switch self {
        case .open: return "Açık"
        case .inProgress: return "İşleniyor"
        case .waitingResponse: return "Yanıt Bekleniyor"
        case .resolved: return "Çözüldü"
        case .closed: return "Kapatıldı"
        }
    }
    
    var color: String {
        switch self {
        case .open: return "#2196F3"
        case .inProgress: return "#FF9800"
        case .waitingResponse: return "#9C27B0"
        case .resolved: return "#4CAF50"
        case .closed: return "#9E9E9E"
        }
    }
}

enum TicketPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Düşük"
        case .medium: return "Orta"
        case .high: return "Yüksek"
        case .urgent: return "Acil"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        case .urgent: return "#9C27B0"
        }
    }
}

struct FAQItem: Codable, Identifiable {
    let id: String
    let category: String
    let question: String
    let answer: String
}
