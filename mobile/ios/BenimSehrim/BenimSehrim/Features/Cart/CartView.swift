import SwiftUI

struct CartView: View {
    @ObservedObject var cartManager = CartManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            if cartManager.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.minus")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("Sepetiniz boş")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Ürün eklemek için mağazaları ziyaret edin.")
                        .foregroundColor(.secondary)
                    
                    Button(action: { dismiss() }) {
                        Text("Alışverişe Başla")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.primaryGreen)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding(40)
            } else {
                List {
                    ForEach(Array(cartManager.items.keys), id: \.id) { product in
                        if let quantity = cartManager.items[product] {
                            CartItemRow(product: product, quantity: quantity)
                        }
                    }
                }
                .listStyle(.plain)
                
                // Bottom Checkout Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Toplam Tutar")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(cartManager.total))₺")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                    }
                    
                    NavigationLink(destination: CheckoutView()) {
                        HStack {
                            Text("Siparişi Onayla")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(height: 56)
                        .padding(.horizontal)
                        .background(Color.primaryGreen)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .shadow(radius: 10)
            }
        }
        .navigationTitle("Sepetim")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
             if !cartManager.items.isEmpty {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button {
                         withAnimation { cartManager.clear() }
                     } label: {
                         Image(systemName: "trash")
                             .foregroundColor(.red)
                     }
                 }
             }
        }
    }
}

struct CartItemRow: View {
    let product: Product
    let quantity: Int
    @ObservedObject var cartManager = CartManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.images.first ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(Int(product.price))₺")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { withAnimation { cartManager.removeFromCart(product) } }) {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 24)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("\(quantity)")
                    .fontWeight(.semibold)
                    .frame(minWidth: 20)
                
                Button(action: { withAnimation { cartManager.addToCart(product) } }) {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                        .background(Color.primaryGreen.opacity(0.1))
                        .foregroundColor(.primaryGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
