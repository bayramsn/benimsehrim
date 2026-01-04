import SwiftUI

struct CheckoutView: View {
    @ObservedObject var cartManager = CartManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedAddress = "Ev - Kuşdili Mah."
    @State private var selectedPayment = "Nakit"
    @State private var note = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Address Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Teslimat Adresi")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                AddressCard(title: "Ev", detail: "Kuşdili Mah. 123. Sok...", icon: "house.fill", isSelected: selectedAddress.contains("Ev")) {
                                    selectedAddress = "Ev - Kuşdili Mah."
                                }
                                
                                AddressCard(title: "İş", detail: "OSB Mah...", icon: "briefcase.fill", isSelected: selectedAddress.contains("İş")) {
                                    selectedAddress = "İş - OSB"
                                }
                                
                                Button(action: {}) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        Text("Ekle")
                                            .font(.caption)
                                    }
                                    .frame(width: 100, height: 120)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Payment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ödeme Yöntemi")
                            .font(.headline)
                        
                        VStack(spacing: 0) {
                            PaymentRow(title: "Nakit", icon: "banknote.fill", isSelected: selectedPayment == "Nakit") {
                                selectedPayment = "Nakit"
                            }
                            Divider()
                            PaymentRow(title: "Kredi Kartı (Kapıda)", icon: "creditcard.fill", isSelected: selectedPayment == "Kredi Kartı") {
                                selectedPayment = "Kredi Kartı"
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Note Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sipariş Notu")
                            .font(.headline)
                        
                        TextField("Zil çalışmıyor vb.", text: $note)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Summary Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Ara Toplam")
                            Spacer()
                            Text("\(Int(cartManager.total))₺")
                        }
                        HStack {
                            Text("Teslimat Ücreti")
                            Spacer()
                            Text("Ücretsiz")
                                .foregroundColor(.primaryGreen)
                        }
                        Divider()
                        HStack {
                            Text("Toplam")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(cartManager.total))₺")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Siparişi Tamamla")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: completeOrder) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Siparişi Onayla (\(Int(cartManager.total))₺)")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding()
                    .background(.ultraThinMaterial)
                }
                .disabled(isLoading)
            }
            .fullScreenCover(isPresented: $showSuccess) {
                OrderSuccessView()
            }
        }
    }
    
    func completeOrder() {
        isLoading = true
        // Mock API Call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            cartManager.clear()
            isLoading = false
            showSuccess = true
        }
    }
}

struct AddressCard: View {
    let title: String
    let detail: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(isSelected ? .primaryGreen : .gray)
                    Text(title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primaryGreen)
                    }
                }
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    
                Spacer()
            }
            .padding()
            .frame(width: 160, height: 120)
            .background(isSelected ? Color.primaryGreen.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryGreen : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct PaymentRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .primaryGreen : .gray)
                    .frame(width: 30)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(.primaryGreen)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    CheckoutView()
}
