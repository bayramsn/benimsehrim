import Foundation
import Combine

class WalletViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var transactions: [WalletTransaction] = []
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        self.balance = 1250.50
        self.transactions = [
            WalletTransaction(id: "1", title: "Para Yükleme", amount: 500.0, date: "Bugün", type: .deposit),
            WalletTransaction(id: "2", title: "Ahi Kasap", amount: -150.0, date: "Dün", type: .payment),
            WalletTransaction(id: "3", title: "Para Gönderme", amount: -200.0, date: "28 Ara", type: .transfer)
        ]
    }
}

struct WalletTransaction: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let date: String
    let type: TransactionType
}

enum TransactionType {
    case deposit, payment, transfer
}
