import SwiftUI

// MARK: - Provider Settings View (Ayarlar içinde iş sağlayıcılar için alan)
struct ProviderSettingsView: View {
    @ObservedObject var roleManager = RoleManager.shared
    @State private var showRegistration = false
    @State private var selectedProviderType: UserRole?
    
    var body: some View {
        List {
            // Current Role Section
            Section {
                HStack {
                    Image(systemName: roleManager.currentRole.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: roleManager.currentRole.color))
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mevcut Rol")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(roleManager.currentRole.displayName)
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if roleManager.isProvider {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            // Provider Registration Section
            if !roleManager.isProvider && !roleManager.isAdmin {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("İş Ortağı Ol")
                            .font(.headline)
                        
                        Text("Platformumuzda hizmet vererek para kazanın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    // Vendor Option
                    ProviderOptionRow(
                        icon: "storefront.fill",
                        title: "Dükkan Aç",
                        subtitle: "Ürünlerinizi satışa sunun",
                        color: "#4CAF50"
                    ) {
                        selectedProviderType = .vendor
                        showRegistration = true
                    }
                    
                    // Taxi Driver Option
                    ProviderOptionRow(
                        icon: "car.fill",
                        title: "Taksi Şoförü Ol",
                        subtitle: "Yolcu taşıyarak kazanın",
                        color: "#FFC107"
                    ) {
                        selectedProviderType = .taxiDriver
                        showRegistration = true
                    }
                    
                    // Courier Option
                    ProviderOptionRow(
                        icon: "shippingbox.fill",
                        title: "Kurye Ol",
                        subtitle: "Teslimat yaparak kazanın",
                        color: "#FF9800"
                    ) {
                        selectedProviderType = .courier
                        showRegistration = true
                    }
                } header: {
                    Text("İş Sağlayıcı Olun")
                }
            }
            
            // Pending Registration
            if let pending = roleManager.pendingRegistration {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Color(hex: pending.status.color))
                            
                            Text("Başvuru Durumu")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(pending.status.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: pending.status.color).opacity(0.2))
                                .foregroundColor(Color(hex: pending.status.color))
                                .cornerRadius(4)
                        }
                        
                        Text("Başvuru Tipi: \(pending.providerType.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Başvuru Tarihi: \(formatDate(pending.createdAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let reason = pending.rejectionReason {
                            Text("Red Sebebi: \(reason)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Bekleyen Başvuru")
                }
            }
            
            // Provider Dashboard (if already a provider)
            if roleManager.isProvider {
                Section {
                    NavigationLink(destination: ProviderDashboardView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.primaryGreen)
                            Text("İş Paneli")
                        }
                    }
                    
                    NavigationLink(destination: ProviderEarningsView()) {
                        HStack {
                            Image(systemName: "turkishlirasign.circle.fill")
                                .foregroundColor(.orange)
                            Text("Kazançlarım")
                        }
                    }
                    
                    NavigationLink(destination: ProviderProfileEditView()) {
                        HStack {
                            Image(systemName: "person.text.rectangle.fill")
                                .foregroundColor(.blue)
                            Text("Profil Düzenle")
                        }
                    }
                } header: {
                    Text("İş Yönetimi")
                }
            }
            
            // Admin Section (only for admins)
            if roleManager.isAdmin {
                Section {
                    NavigationLink(destination: AdminDashboardView()) {
                        HStack {
                            Image(systemName: "gear.badge.checkmark")
                                .foregroundColor(.purple)
                            Text("Admin Paneli")
                        }
                    }
                    
                    if roleManager.isSuperAdmin {
                        NavigationLink(destination: SuperAdminView()) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.red)
                                Text("Süper Admin")
                            }
                        }
                    }
                } header: {
                    Text("Yönetim")
                }
            }
        }
        .navigationTitle("İş Sağlayıcı")
        .sheet(isPresented: $showRegistration) {
            if let type = selectedProviderType {
                ProviderRegistrationView(providerType: type)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct ProviderOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: color))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Provider Registration View
struct ProviderRegistrationView: View {
    let providerType: UserRole
    @Environment(\.dismiss) var dismiss
    @ObservedObject var roleManager = RoleManager.shared
    
    // Common fields
    @State private var fullName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    
    // Vendor fields
    @State private var storeName = ""
    @State private var storeCategory = ""
    
    // Driver fields
    @State private var licenseNumber = ""
    @State private var vehiclePlate = ""
    @State private var vehicleModel = ""
    @State private var vehicleColor = ""
    
    // Courier fields
    @State private var vehicleType: VehicleType = .motorcycle
    
    // Documents
    @State private var showDocumentPicker = false
    @State private var selectedDocumentType = ""
    @State private var documents: [String: String] = [:]
    
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Header
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: providerType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: providerType.color))
                        
                        Text("\(providerType.displayName) Başvurusu")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(getDescription())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                // Personal Info
                Section("Kişisel Bilgiler") {
                    TextField("Ad Soyad", text: $fullName)
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("E-posta (isteğe bağlı)", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                // Provider-specific fields
                switch providerType {
                case .vendor:
                    vendorFields
                case .taxiDriver:
                    taxiDriverFields
                case .courier:
                    courierFields
                default:
                    EmptyView()
                }
                
                // Documents
                Section("Belgeler") {
                    ForEach(getRequiredDocuments(), id: \.self) { doc in
                        DocumentUploadRow(
                            documentType: doc,
                            isUploaded: documents[doc] != nil,
                            onUpload: {
                                selectedDocumentType = doc
                                showDocumentPicker = true
                            }
                        )
                    }
                }
                
                // Terms
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Başvuru yaparak aşağıdakileri kabul etmiş olursunuz:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Platform kullanım koşulları")
                        Text("• Gizlilik politikası")
                        Text("• İş ortağı sözleşmesi")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Submit
                Section {
                    Button(action: submitApplication) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Başvuruyu Gönder")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .navigationTitle("Başvuru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Başvuru Gönderildi", isPresented: $showSuccess) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Başvurunuz incelemeye alındı. En kısa sürede size dönüş yapılacaktır.")
            }
        }
    }
    
    private var vendorFields: some View {
        Section("Dükkan Bilgileri") {
            TextField("Dükkan Adı", text: $storeName)
            TextField("Adres", text: $address)
            Picker("Kategori", selection: $storeCategory) {
                Text("Seçin").tag("")
                Text("Market").tag("market")
                Text("Restoran").tag("restaurant")
                Text("Fırın").tag("bakery")
                Text("Kasap").tag("butcher")
                Text("Eczane").tag("pharmacy")
                Text("Diğer").tag("other")
            }
        }
    }
    
    private var taxiDriverFields: some View {
        Section("Araç & Ehliyet Bilgileri") {
            TextField("Ehliyet Numarası", text: $licenseNumber)
            TextField("Plaka", text: $vehiclePlate)
            TextField("Araç Modeli", text: $vehicleModel)
            TextField("Araç Rengi", text: $vehicleColor)
        }
    }
    
    private var courierFields: some View {
        Section("Araç Bilgileri") {
            Picker("Araç Tipi", selection: $vehicleType) {
                ForEach([VehicleType.motorcycle, .bicycle, .car, .walking], id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            
            if vehicleType != .walking && vehicleType != .bicycle {
                TextField("Plaka", text: $vehiclePlate)
            }
        }
    }
    
    private func getDescription() -> String {
        switch providerType {
        case .vendor:
            return "Dükkanınızı açın, ürünlerinizi satışa sunun ve binlerce müşteriye ulaşın."
        case .taxiDriver:
            return "Aracınızla yolcu taşıyarak esnek çalışma saatleriyle para kazanın."
        case .courier:
            return "Teslimat yaparak kendi programınızda çalışın ve kazanın."
        default:
            return ""
        }
    }
    
    private func getRequiredDocuments() -> [String] {
        switch providerType {
        case .vendor:
            return ["Kimlik Belgesi", "Vergi Levhası", "İşyeri Ruhsatı"]
        case .taxiDriver:
            return ["Kimlik Belgesi", "Ehliyet", "Ruhsat", "Sigorta", "Adli Sicil"]
        case .courier:
            return ["Kimlik Belgesi", "Ehliyet (motorlu araç için)"]
        default:
            return []
        }
    }
    
    private var isFormValid: Bool {
        guard !fullName.isEmpty && !phone.isEmpty else { return false }
        
        switch providerType {
        case .vendor:
            return !storeName.isEmpty && !address.isEmpty && !storeCategory.isEmpty
        case .taxiDriver:
            return !licenseNumber.isEmpty && !vehiclePlate.isEmpty && !vehicleModel.isEmpty
        case .courier:
            return true
        default:
            return false
        }
    }
    
    private func submitApplication() {
        isSubmitting = true
        
        switch providerType {
        case .vendor:
            _ = roleManager.registerAsVendor(
                storeName: storeName,
                storeCategory: storeCategory,
                address: address,
                phone: phone,
                documents: documents
            )
        case .taxiDriver:
            _ = roleManager.registerAsTaxiDriver(
                licenseNumber: licenseNumber,
                vehiclePlate: vehiclePlate,
                vehicleModel: vehicleModel,
                phone: phone,
                documents: documents
            )
        case .courier:
            _ = roleManager.registerAsCourier(
                vehicleType: vehicleType,
                vehiclePlate: vehiclePlate.isEmpty ? nil : vehiclePlate,
                phone: phone,
                documents: documents
            )
        default:
            break
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            showSuccess = true
        }
    }
}

struct DocumentUploadRow: View {
    let documentType: String
    let isUploaded: Bool
    let onUpload: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isUploaded ? "checkmark.circle.fill" : "doc.badge.plus")
                .foregroundColor(isUploaded ? .green : .gray)
            
            Text(documentType)
            
            Spacer()
            
            Button(action: onUpload) {
                Text(isUploaded ? "Değiştir" : "Yükle")
                    .font(.subheadline)
                    .foregroundColor(.primaryGreen)
            }
        }
    }
}

// MARK: - Provider Dashboard View
struct ProviderDashboardView: View {
    @ObservedObject var roleManager = RoleManager.shared
    @ObservedObject var operationsManager = BusinessOperationsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                AvailabilityStatusButton()
                    .padding(.horizontal)
                
                // Quick Stats
                if let summary = operationsManager.dailySummary {
                    DailySummaryCard(summary: summary)
                        .padding(.horizontal)
                }
                
                // Daily Goal (for drivers)
                if roleManager.currentRole == .taxiDriver || roleManager.currentRole == .courier {
                    DailyGoalProgressView(currentJobs: 5, dailyGoal: 10)
                        .padding(.horizontal)
                }
                
                // Suggestions
                if !operationsManager.productSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Öneriler")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(operationsManager.productSuggestions) { suggestion in
                            ProductSuggestionCard(suggestion: suggestion) {
                                // Handle action
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("İş Paneli")
    }
}

// MARK: - Provider Earnings View
struct ProviderEarningsView: View {
    @State private var selectedPeriod = "week"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Text("Bu Hafta")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("₺2,450.00")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primaryGreen)
                    
                    Text("+15% geçen haftaya göre")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section("Kazanç Detayı") {
                EarningRow(title: "Sipariş Gelirleri", amount: 2100)
                EarningRow(title: "Bahşişler", amount: 350)
                EarningRow(title: "Bonuslar", amount: 0)
            }
            
            Section("Kesintiler") {
                EarningRow(title: "Platform Komisyonu", amount: -210, isNegative: true)
                EarningRow(title: "Vergi Kesintisi", amount: -0, isNegative: true)
            }
            
            Section {
                HStack {
                    Text("Net Kazanç")
                        .fontWeight(.bold)
                    Spacer()
                    Text("₺2,240.00")
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationTitle("Kazançlarım")
    }
}

struct EarningRow: View {
    let title: String
    let amount: Double
    var isNegative: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(String(format: "%@₺%.2f", isNegative ? "" : "+", abs(amount)))
                .foregroundColor(isNegative ? .red : .primary)
        }
    }
}

// MARK: - Provider Profile Edit View
struct ProviderProfileEditView: View {
    @ObservedObject var roleManager = RoleManager.shared
    
    var body: some View {
        List {
            Section("Profil Bilgileri") {
                // Provider-specific profile fields
                Text("Profil düzenleme alanı")
            }
            
            Section("Belgeler") {
                Text("Belge güncelleme")
            }
            
            Section("Çalışma Saatleri") {
                Text("Çalışma saatleri ayarları")
            }
        }
        .navigationTitle("Profil Düzenle")
    }
}

// MARK: - Admin Dashboard View
struct AdminDashboardView: View {
    @ObservedObject var adminManager = AdminManager.shared
    
    var body: some View {
        List {
            // Stats Overview
            Section("Genel Bakış") {
                if let stats = adminManager.operationStats {
                    StatRow(title: "Bugünkü Siparişler", value: "\(stats.totalOrders)")
                    StatRow(title: "Tamamlanan", value: "\(stats.completedOrders)")
                    StatRow(title: "Toplam Gelir", value: String(format: "₺%.2f", stats.totalRevenue))
                    StatRow(title: "Aktif Esnaf", value: "\(stats.activeVendors)")
                    StatRow(title: "Aktif Şoför", value: "\(stats.activeDrivers)")
                }
            }
            
            // Pending Approvals
            Section("Bekleyen Onaylar") {
                NavigationLink("Esnaf Başvuruları (\(adminManager.pendingVendors.count))") {
                    PendingApprovalsView(type: .vendor)
                }
                
                NavigationLink("Şoför Başvuruları (\(adminManager.pendingDrivers.count))") {
                    PendingApprovalsView(type: .taxiDriver)
                }
            }
            
            // Crisis Alerts
            if !adminManager.crisisAlerts.isEmpty {
                Section("Kriz Alarmları") {
                    ForEach(adminManager.crisisAlerts.filter { !$0.isResolved }) { alert in
                        CrisisAlertCard(alert: alert) {
                            adminManager.resolveCrisis(alertId: alert.id, note: nil)
                        }
                    }
                }
            }
            
            // Quick Actions
            Section("Hızlı İşlemler") {
                NavigationLink("Kullanıcı Yönetimi") {
                    Text("Kullanıcı Yönetimi")
                }
                
                NavigationLink("Saha Notları") {
                    FieldNotesView()
                }
                
                NavigationLink("Kampanya Moderasyonu") {
                    Text("Kampanya Moderasyonu")
                }
            }
        }
        .navigationTitle("Admin Paneli")
        .onAppear {
            adminManager.loadOperationStats()
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Super Admin View
struct SuperAdminView: View {
    @ObservedObject var superAdminManager = SuperAdminManager.shared
    
    var body: some View {
        List {
            // System Settings
            Section("Sistem Ayarları") {
                if let settings = superAdminManager.systemSettings {
                    NavigationLink("Genel Ayarlar") {
                        SystemSettingsView(settings: settings)
                    }
                    
                    Toggle("Bakım Modu", isOn: .constant(settings.maintenanceMode))
                    
                    HStack {
                        Text("Komisyon Oranı")
                        Spacer()
                        Text("%\(Int(settings.commissionRate))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // City Management
            Section("Şehir Yönetimi") {
                ForEach(superAdminManager.cityConfigs) { city in
                    NavigationLink {
                        CityConfigView(config: city)
                    } label: {
                        HStack {
                            Text(city.cityName)
                            Spacer()
                            Circle()
                                .fill(city.isActive ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                
                Button("Yeni Şehir Ekle") {
                    // Add new city
                }
            }
            
            // Admin Management
            Section("Admin Yönetimi") {
                ForEach(superAdminManager.adminUsers) { admin in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(admin.name)
                                .fontWeight(.medium)
                            Text(admin.phone)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(admin.isActive ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
                
                Button("Yeni Admin Ekle") {
                    // Add new admin
                }
            }
            
            // Statistics
            Section("İstatistikler") {
                StatRow(title: "Toplam Esnaf", value: "\(superAdminManager.totalVendors)")
                StatRow(title: "Toplam Şoför", value: "\(superAdminManager.totalDrivers)")
                StatRow(title: "Toplam Kurye", value: "\(superAdminManager.totalCouriers)")
                StatRow(title: "Bekleyen Başvuru", value: "\(superAdminManager.pendingRequests)")
            }
        }
        .navigationTitle("Süper Admin")
    }
}

// MARK: - Supporting Views
struct PendingApprovalsView: View {
    let type: UserRole
    
    var body: some View {
        List {
            Text("Bekleyen \(type.displayName) başvuruları")
        }
        .navigationTitle("Bekleyen Başvurular")
    }
}

struct FieldNotesView: View {
    @ObservedObject var adminManager = AdminManager.shared
    
    var body: some View {
        List {
            ForEach(adminManager.fieldNotes) { note in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(note.targetName)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(note.noteType.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: note.noteType.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text(note.note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Saha Notları")
    }
}

struct SystemSettingsView: View {
    let settings: SystemSettings
    
    var body: some View {
        Form {
            Section("Uygulama") {
                Text("Uygulama Adı: \(settings.appName)")
                Text("Min. Versiyon: \(settings.minAppVersion)")
            }
            
            Section("İletişim") {
                Text("Destek E-posta: \(settings.supportEmail)")
                Text("Destek Tel: \(settings.supportPhone)")
            }
            
            Section("Ücretler") {
                Text("Komisyon: %\(Int(settings.commissionRate))")
                Text("KDV: %\(Int(settings.taxRate))")
            }
        }
        .navigationTitle("Sistem Ayarları")
    }
}

struct CityConfigView: View {
    let config: CityConfig
    
    var body: some View {
        Form {
            Section("Şehir Bilgileri") {
                Text("Şehir: \(config.cityName)")
                Text("Kod: \(config.cityCode)")
                Text("Durum: \(config.isActive ? "Aktif" : "Pasif")")
            }
            
            Section("Teslimat Ücretleri") {
                Text("Başlangıç: ₺\(String(format: "%.2f", config.deliveryFeeBase))")
                Text("Km Başı: ₺\(String(format: "%.2f", config.deliveryFeePerKm))")
            }
            
            Section("Taksi Ücretleri") {
                Text("Açılış: ₺\(String(format: "%.2f", config.taxiFareBase))")
                Text("Km Başı: ₺\(String(format: "%.2f", config.taxiFarePerKm))")
                Text("Dk Başı: ₺\(String(format: "%.2f", config.taxiFarePerMinute))")
            }
            
            Section("Çalışma Saatleri") {
                Text("Başlangıç: \(config.operatingHoursStart):00")
                Text("Bitiş: \(config.operatingHoursEnd):00")
            }
        }
        .navigationTitle(config.cityName)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProviderSettingsView()
    }
}
