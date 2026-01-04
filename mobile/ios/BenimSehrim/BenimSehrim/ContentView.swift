import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isLoggedIn)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
            
            StoresView()
                .tabItem {
                    Label("Mağazalar", systemImage: "storefront.fill")
                }
                .tag(1)
            
            if #available(iOS 17.0, *) {
                TaxiView()
                    .tabItem {
                        Label("Taksi", systemImage: "car.fill")
                    }
                    .tag(2)
            } else {
                TaxiPlaceholderView()
                    .tabItem {
                        Label("Taksi", systemImage: "car.fill")
                    }
                    .tag(2)
            }
            
            if #available(iOS 17.0, *) {
                CallCourierView()
                    .tabItem {
                        Label("Kurye", systemImage: "paperplane.fill")
                    }
                    .tag(5)
            } else {
                CourierPlaceholderView()
                    .tabItem {
                        Label("Kurye", systemImage: "paperplane.fill")
                    }
                    .tag(5)
            }
            
            OrdersView()
                .tabItem {
                    Label("Siparişler", systemImage: "cart.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(Color.primaryGreen)
    }
}

// Placeholder views for iOS 16
struct TaxiPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Taksi özelliği iOS 17+ gerektirir")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct CourierPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Kurye özelliği iOS 17+ gerektirir")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(NetworkManager.shared)
}
