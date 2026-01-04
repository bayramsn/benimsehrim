import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [.primaryGreen, .primaryGreenLight]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.white)
                                .frame(width: 120, height: 120)
                            
                            Text("🏙️")
                                .font(.system(size: 60))
                        }
                        
                        Text("Benim Şehrim")
                            .font(.headlineLarge)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text("Şehrin Cebinde")
                            .font(.bodyLarge)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Login Card
                    VStack(spacing: 24) {
                        Text("Giriş Yap")
                            .font(.headlineSmall)
                            .fontWeight(.semibold)
                        
                        Text("Telefon numaranızı girin, size doğrulama kodu gönderelim")
                            .font(.bodyMedium)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Phone Input
                        HStack {
                            Text("+90")
                                .foregroundColor(.secondary)
                            
                            TextField("5XX XXX XX XX", text: $viewModel.phone)
                                .keyboardType(.phonePad)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if let error = viewModel.error {
                            Text(error)
                                .font(.bodySmall)
                                .foregroundColor(.red)
                        }
                        
                        // Continue Button
                        Button(action: viewModel.sendOtp) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Devam Et")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.isPhoneValid ? Color.primaryGreen : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isPhoneValid || viewModel.isLoading)
                    }
                    .padding(24)
                    .background(.white)
                    .cornerRadius(24)
                    .shadow(radius: 10)
                    .padding(.horizontal)
                    
                    // Terms
                    Text("Devam ederek Kullanım Koşulları ve Gizlilik Politikası'nı kabul etmiş olursunuz.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 32)
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToOtp) {
                OtpView(phone: viewModel.fullPhone)
            }
        }
    }
}

// MARK: - Login ViewModel
class LoginViewModel: ObservableObject {
    @Published var phone: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var navigateToOtp: Bool = false
    
    var isPhoneValid: Bool {
        phone.count >= 10
    }
    
    var fullPhone: String {
        "+90\(phone)"
    }
    
    func sendOtp() {
        guard isPhoneValid else { return }
        
        isLoading = true
        error = nil
        
        // TEST MODE: Skip OTP sending in DEBUG
        #if DEBUG
        let isTestMode = true
        #else
        let isTestMode = false
        #endif
        
        if isTestMode {
            // Test mode - directly navigate to OTP screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isLoading = false
                self.navigateToOtp = true
            }
            return
        }
        
        Task {
            do {
                let _ = try await NetworkManager.shared.sendOtp(phone: fullPhone)
                await MainActor.run {
                    self.isLoading = false
                    self.navigateToOtp = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Bir hata oluştu. Lütfen tekrar deneyin."
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
