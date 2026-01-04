import SwiftUI

struct RegisterView: View {
    let phone: String
    
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.primaryGreen, .primaryGreenLight]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)
                    
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white)
                            .frame(width: 80, height: 80)
                        
                        Text("👋")
                            .font(.system(size: 40))
                    }
                    
                    Text("Hoş Geldiniz!")
                        .font(.headlineMedium)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text("Hesabınızı oluşturmak için bilgilerinizi girin")
                        .font(.bodyMedium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Form Card
                    VStack(spacing: 16) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ad Soyad *")
                                .font(.labelMedium)
                                .foregroundColor(.secondary)
                            
                            TextField("Adınız Soyadınız", text: $viewModel.name)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-posta (Opsiyonel)")
                                .font(.labelMedium)
                                .foregroundColor(.secondary)
                            
                            TextField("ornek@email.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // City Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Şehir *")
                                .font(.labelMedium)
                                .foregroundColor(.secondary)
                            
                            Menu {
                                ForEach(viewModel.cities) { city in
                                    Button(city.name) {
                                        viewModel.selectCity(city)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedCity?.name ?? "Şehir Seçin")
                                        .foregroundColor(viewModel.selectedCity == nil ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // District Picker
                        if viewModel.selectedCity != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("İlçe *")
                                    .font(.labelMedium)
                                    .foregroundColor(.secondary)
                                
                                Menu {
                                    ForEach(viewModel.districts) { district in
                                        Button(district.name) {
                                            viewModel.selectedDistrict = district
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedDistrict?.name ?? "İlçe Seçin")
                                            .foregroundColor(viewModel.selectedDistrict == nil ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        if let error = viewModel.error {
                            Text(error)
                                .font(.bodySmall)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: { viewModel.register(phone: phone) }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Hesap Oluştur")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.isFormValid ? Color.primaryGreen : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    }
                    .padding(24)
                    .background(.white)
                    .cornerRadius(24)
                    .shadow(radius: 10)
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            viewModel.loadCities()
        }
    }
}

// MARK: - Register ViewModel
class RegisterViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var cities: [City] = []
    @Published var selectedCity: City?
    @Published var districts: [District] = []
    @Published var selectedDistrict: District?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // TEST MODE flag
    #if DEBUG
    private let isTestMode = true
    #else
    private let isTestMode = false
    #endif
    
    var isFormValid: Bool {
        !name.isEmpty && selectedCity != nil && selectedDistrict != nil
    }
    
    func loadCities() {
        if isTestMode {
            // Test mode - use mock cities directly
            self.cities = [
                City(id: "1", name: "Kırşehir", code: "40", isActive: true),
                City(id: "2", name: "Ankara", code: "06", isActive: true),
                City(id: "3", name: "İstanbul", code: "34", isActive: true)
            ]
            return
        }
        
        Task {
            do {
                let fetchedCities = try await NetworkManager.shared.getCities()
                await MainActor.run {
                    self.cities = fetchedCities
                }
            } catch {
                await MainActor.run {
                    // Fallback cities
                    self.cities = [
                        City(id: "1", name: "Kırşehir", code: "40", isActive: true),
                        City(id: "2", name: "Ankara", code: "06", isActive: true),
                        City(id: "3", name: "İstanbul", code: "34", isActive: true)
                    ]
                }
            }
        }
    }
    
    func selectCity(_ city: City) {
        self.selectedCity = city
        self.selectedDistrict = nil
        self.districts = []
        loadDistricts(cityId: city.id)
    }
    
    func loadDistricts(cityId: String) {
        if isTestMode {
            // Test mode - use mock districts directly
            switch cityId {
            case "1":
                self.districts = [
                    District(id: "101", name: "Merkez", cityId: "1", isActive: true),
                    District(id: "102", name: "Kaman", cityId: "1", isActive: true),
                    District(id: "103", name: "Mucur", cityId: "1", isActive: true)
                ]
            case "2":
                self.districts = [
                    District(id: "201", name: "Çankaya", cityId: "2", isActive: true),
                    District(id: "202", name: "Keçiören", cityId: "2", isActive: true),
                    District(id: "203", name: "Mamak", cityId: "2", isActive: true)
                ]
            case "3":
                self.districts = [
                    District(id: "301", name: "Kadıköy", cityId: "3", isActive: true),
                    District(id: "302", name: "Beşiktaş", cityId: "3", isActive: true),
                    District(id: "303", name: "Üsküdar", cityId: "3", isActive: true)
                ]
            default:
                self.districts = [District(id: "999", name: "Merkez", cityId: cityId, isActive: true)]
            }
            return
        }
        
        Task {
            do {
                let fetchedDistricts = try await NetworkManager.shared.getDistricts(cityId: cityId)
                await MainActor.run {
                    self.districts = fetchedDistricts
                }
            } catch {
                await MainActor.run {
                     // Fallback Mock
                     if cityId == "1" {
                         self.districts = [
                             District(id: "101", name: "Merkez", cityId: "1", isActive: true),
                             District(id: "102", name: "Kaman", cityId: "1", isActive: true)
                         ]
                     } else {
                         self.districts = [District(id: "999", name: "Merkez", cityId: cityId, isActive: true)]
                     }
                }
            }
        }
    }
    
    func register(phone: String) {
        guard isFormValid, let cityId = selectedCity?.id, let districtId = selectedDistrict?.id else { return }
        
        isLoading = true
        error = nil
        
        if isTestMode {
            // Test mode - simulate successful registration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = false
                
                // Create mock user and tokens
                let mockUser = User(
                    id: "test-user-123",
                    phone: phone,
                    name: self.name,
                    email: self.email.isEmpty ? nil : self.email,
                    avatarUrl: nil,
                    role: "user",
                    city: self.selectedCity,
                    district: self.selectedDistrict,
                    balance: 0.0,
                    createdAt: "2024-01-01T00:00:00Z"
                )
                
                AuthManager.shared.saveTokens(
                    accessToken: "test-access-token-\(UUID().uuidString)",
                    refreshToken: "test-refresh-token-\(UUID().uuidString)"
                )
                AuthManager.shared.saveUser(mockUser)
            }
            return
        }
        
        Task {
            do {
                let response = try await NetworkManager.shared.register(
                    phone: phone,
                    name: name,
                    email: email.isEmpty ? nil : email,
                    cityId: cityId,
                    districtId: districtId
                )
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if let accessToken = response.accessToken,
                       let refreshToken = response.refreshToken {
                        AuthManager.shared.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
                        if let user = response.user {
                            AuthManager.shared.saveUser(user)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Kayıt başarısız. Lütfen tekrar deneyin."
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(phone: "+905001234567")
    }
}
