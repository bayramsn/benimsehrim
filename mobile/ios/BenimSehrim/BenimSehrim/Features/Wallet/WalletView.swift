import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack {
                // Balance Card
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .cornerRadius(16)
                    
                    VStack(alignment: .leading) {
                        Text("Toplam Bakiye")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.subheadline)
                        
                        Text("\(String(format: "%.2f", viewModel.balance)) ₺")
                            .foregroundColor(.white)
                            .font(.system(size: 32, weight: .bold))
                            .padding(.top, 4)
                        
                        Spacer()
                        
                        HStack {
                            Text("TR12 3456 7890")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                            Spacer()
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                }
                .frame(height: 180)
                .padding()
                .shadow(radius: 5)
                
                // Actions
                HStack(spacing: 20) {
                    WalletActionButton(icon: "plus", title: "Yükle")
                    WalletActionButton(icon: "paperplane", title: "Gönder")
                    WalletActionButton(icon: "qrcode", title: "Öde")
                }
                .padding(.horizontal)
                
                // Transactions
                List {
                    Section(header: Text("Son İşlemler")) {
                        ForEach(viewModel.transactions) { transaction in
                            HStack {
                                Image(systemName: getIcon(for: transaction.type))
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(transaction.title)
                                        .font(.body)
                                    Text(transaction.date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text("\(transaction.amount > 0 ? "+" : "")\(String(format: "%.2f", transaction.amount)) ₺")
                                    .fontWeight(.bold)
                                    .foregroundColor(transaction.amount > 0 ? .green : .red)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Cüzdanım")
        }
    }
    
    func getIcon(for type: TransactionType) -> String {
        switch type {
        case .deposit: return "arrow.down.circle.fill"
        case .payment: return "cart.fill"
        case .transfer: return "arrow.up.circle.fill"
        }
    }
}

struct WalletActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}
