import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var roleManager = RoleManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryGreen)
                                .frame(width: 64, height: 64)
                            
                            Text(String(authManager.userName?.prefix(1) ?? "?").uppercased())
                                .font(.headlineMedium)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.userName ?? "Kullanıcı")
                                .font(.titleLarge)
                                .fontWeight(.bold)
                            
                            Text(authManager.userPhone ?? "")
                                .font(.bodyMedium)
                                .foregroundColor(.secondary)
                            
                            // Role Badge
                            HStack(spacing: 4) {
                                Image(systemName: roleManager.currentRole.icon)
                                    .font(.caption)
                                Text(roleManager.currentRole.displayName)
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: roleManager.currentRole.color))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: roleManager.currentRole.color).opacity(0.15))
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "pencil")
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Provider Section (İş Sağlayıcı)
                Section {
                    NavigationLink(destination: ProviderSettingsView()) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("İş Ortağı Ol")
                                    .font(.body)
                                
                                if roleManager.isProvider {
                                    Text("İş panelinizi yönetin")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if roleManager.pendingRegistration != nil {
                                    Text("Başvurunuz inceleniyor")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Esnaf, Taksi veya Kurye olun")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if roleManager.isProvider {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    
                    // Admin Panel (only for admins)
                    if roleManager.isAdmin {
                        NavigationLink(destination: AdminDashboardView()) {
                            HStack {
                                Image(systemName: roleManager.isSuperAdmin ? "crown.fill" : "shield.fill")
                                    .foregroundColor(roleManager.isSuperAdmin ? .red : .purple)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(roleManager.isSuperAdmin ? "Süper Admin" : "Admin Paneli")
                                        .font(.body)
                                    
                                    Text("Sistemi yönetin")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("İş Sağlayıcı")
                }
                
                // Menu Items
                Section {
                    NavigationLink(destination: AddressesView()) {
                        Label("Adreslerim", systemImage: "location")
                    }

                    NavigationLink(destination: WalletView()) {
                        Label("Cüzdanım", systemImage: "creditcard")
                    }

                    NavigationLink(destination: FavoritesView()) {
                        Label("Favorilerim", systemImage: "heart")
                    }
                    
                    NavigationLink(destination: OrdersView()) {
                        Label("Sipariş Geçmişi", systemImage: "bag")
                    }
                    
                    NavigationLink(destination: NotificationListView()) {
                        HStack {
                            Label("Bildirimler", systemImage: "bell")
                            
                            Spacer()
                            
                            if NotificationManager.shared.unreadCount > 0 {
                                Text("\(NotificationManager.shared.unreadCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: SupportView()) {
                        Label("Yardım & Destek", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Ayarlar", systemImage: "gearshape")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("Hakkında", systemImage: "info.circle")
                    }
                }
                
                // Logout
                Section {
                    Button(action: { authManager.logout() }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Çıkış Yap")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // Version
                Section {
                    HStack {
                        Spacer()
                        Text("Versiyon 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Profilim")
            .onAppear {
                roleManager.checkAndSetSuperAdmin()
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var localization = LocalizationManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        Form {
            Section("Dil") {
                Picker("Uygulama Dili", selection: $localization.currentLanguage) {
                    ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                        }
                        .tag(language)
                    }
                }
            }
            
            Section("Bildirimler") {
                Toggle("Sipariş Bildirimleri", isOn: $notificationManager.notificationSettings.orderUpdates)
                Toggle("Kampanya Bildirimleri", isOn: $notificationManager.notificationSettings.promotions)
                Toggle("Taksi Bildirimleri", isOn: $notificationManager.notificationSettings.taxiUpdates)
                Toggle("Mesaj Bildirimleri", isOn: $notificationManager.notificationSettings.chatMessages)
                Toggle("Ses", isOn: $notificationManager.notificationSettings.soundEnabled)
                Toggle("Titreşim", isOn: $notificationManager.notificationSettings.vibrationEnabled)
            }
            
            Section("Gizlilik") {
                NavigationLink(destination: KVKKConsentView(onAccept: {})) {
                    Text("KVKK Aydınlatma Metni")
                }
                
                NavigationLink("Kullanım Koşulları") {
                    Text("Kullanım Koşulları")
                }
                
                NavigationLink("Gizlilik Politikası") {
                    Text("Gizlilik Politikası")
                }
            }
            
            Section("Hesap") {
                Button("Önbelleği Temizle") {
                    // Clear cache
                }
                
                Button("Hesabı Sil", role: .destructive) {
                    // Delete account
                }
            }
        }
        .navigationTitle("Ayarlar")
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primaryGreen)
                    
                    Text("Benim Şehrim")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Yerel süper uygulama")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section("İletişim") {
                HStack {
                    Image(systemName: "envelope")
                    Text("destek@benimsehrim.com")
                }
                
                HStack {
                    Image(systemName: "phone")
                    Text("+90 850 123 45 67")
                }
                
                HStack {
                    Image(systemName: "globe")
                    Text("www.benimsehrim.com")
                }
            }
            
            Section("Sosyal Medya") {
                HStack {
                    Image(systemName: "camera")
                    Text("@benimsehrim")
                }
                
                HStack {
                    Image(systemName: "bubble.left")
                    Text("@benimsehrim")
                }
            }
            
            Section {
                Text("© 2026 Benim Şehrim. Tüm hakları saklıdır.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Hakkında")
    }
}

// MARK: - Addresses View (Placeholder)
struct AddressesView: View {
    var body: some View {
        List {
            Text("Adreslerim sayfası")
        }
        .navigationTitle("Adreslerim")
    }
}
