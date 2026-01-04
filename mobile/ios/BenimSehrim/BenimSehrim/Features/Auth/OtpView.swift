import SwiftUI

struct OtpView: View {
    let phone: String
    
    @StateObject private var viewModel = OtpViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.primaryGreen, .primaryGreenLight]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: 80, height: 80)
                    
                    Text("📱")
                        .font(.system(size: 40))
                }
                
                Text("Doğrulama Kodu")
                    .font(.headlineMedium)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Text("\(phone) numarasına gönderilen 6 haneli kodu giriniz")
                    .font(.bodyMedium)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // OTP Card
                VStack(spacing: 24) {
                    TextField("______", text: $viewModel.otp)
                        .keyboardType(.numberPad)
                        .font(.headlineMedium)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($isFocused)
                        .onChange(of: viewModel.otp) { _ in
                            if viewModel.otp.count == 6 {
                                viewModel.verifyOtp(phone: phone)
                            }
                        }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: { viewModel.verifyOtp(phone: phone) }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Doğrula")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.otp.count == 6 ? Color.primaryGreen : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.otp.count != 6 || viewModel.isLoading)
                    
                    if viewModel.countdown > 0 {
                        Text("Tekrar gönder (\(viewModel.countdown)s)")
                            .font(.bodyMedium)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Kodu Tekrar Gönder") {
                            viewModel.resendOtp(phone: phone)
                        }
                    }
                }
                .padding(24)
                .background(.white)
                .cornerRadius(24)
                .shadow(radius: 10)
                .padding(.horizontal)
                
                Spacer()
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
        .navigationDestination(isPresented: $viewModel.navigateToRegister) {
            RegisterView(phone: phone)
        }
        .onAppear {
            isFocused = true
            viewModel.startCountdown()
        }
    }
}

// MARK: - OTP ViewModel
class OtpViewModel: ObservableObject {
    @Published var otp: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var countdown: Int = 120
    @Published var navigateToRegister: Bool = false
    
    private var timer: Timer?
    
    func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                self.timer?.invalidate()
            }
        }
    }
    
    func verifyOtp(phone: String) {
        guard otp.count == 6 else { return }
        
        isLoading = true
        error = nil
        
        // TEST MODE: Accept any 6-digit OTP code
        #if DEBUG
        let isTestMode = true
        #else
        let isTestMode = false
        #endif
        
        if isTestMode {
            // Test mode - accept any OTP and simulate new user
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = false
                // Simulate new user - navigate to register
                self.navigateToRegister = true
            }
            return
        }
        
        Task {
            do {
                let response = try await NetworkManager.shared.verifyOtp(phone: phone, otp: otp)
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if response.isNewUser == true {
                        self.navigateToRegister = true
                    } else if let accessToken = response.accessToken,
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
                    self.error = "Geçersiz kod. Lütfen tekrar deneyin."
                }
            }
        }
    }
    
    func resendOtp(phone: String) {
        Task {
            do {
                let _ = try await NetworkManager.shared.sendOtp(phone: phone)
                await MainActor.run {
                    self.countdown = 120
                    self.otp = ""
                    self.startCountdown()
                }
            } catch {
                await MainActor.run {
                    self.error = "Kod gönderilemedi"
                }
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

#Preview {
    NavigationStack {
        OtpView(phone: "+905001234567")
    }
}
