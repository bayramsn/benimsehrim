import SwiftUI

struct FavoritesView: View {
    @State private var favoriteStores: [Store] = []
    
    var body: some View {
        NavigationStack {
            List(favoriteStores) { store in
                HStack(alignment: .top, spacing: 12) {
                    if let bannerUrl = store.bannerUrl, let url = URL(string: bannerUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name)
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", store.rating))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("(\(store.reviewCount))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text(store.isOpen ? "Açık" : "Kapalı")
                            .font(.caption)
                            .foregroundColor(store.isOpen ? .green : .red)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Remove from favorites logic
                        if let index = favoriteStores.firstIndex(where: { $0.id == store.id }) {
                            favoriteStores.remove(at: index)
                        }
                    }) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 4)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Favorilerim")
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    func loadFavorites() {
        // Mock Data
        self.favoriteStores = [
             Store(id: "1", name: "Ahi Kasap", logoUrl: nil, bannerUrl: "https://picsum.photos/200/300", rating: 4.8, reviewCount: 120, isOpen: true, distance: 1.2, deliveryTime: "30 dk", minOrder: 100, deliveryFee: 0, categories: [], isFavorite: true),
             Store(id: "2", name: "Lezzet Döner", logoUrl: nil, bannerUrl: "https://picsum.photos/200/301", rating: 4.5, reviewCount: 85, isOpen: true, distance: 2.5, deliveryTime: "45 dk", minOrder: 150, deliveryFee: 20, categories: [], isFavorite: true)
        ]
    }
}
