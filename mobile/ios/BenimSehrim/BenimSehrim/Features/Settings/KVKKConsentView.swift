import SwiftUI

struct KVKKConsentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasReadPrivacyPolicy = false
    @State private var hasReadTerms = false
    @State private var allowsDataProcessing = false
    @State private var allowsLocationTracking = false
    @State private var allowsMarketing = false
    
    var onAccept: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kişisel Verilerin Korunması")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("6698 sayılı KVKK kapsamında kişisel verilerinizin işlenmesi için açık rızanıza ihtiyacımız var.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Zorunlu Rızalar
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Zorunlu Rızalar")
                            .font(.headline)
                        
                        ConsentToggle(
                            title: "Gizlilik Politikasını Okudum",
                            description: "Kişisel verilerinizin nasıl işlendiğini öğrenin",
                            isOn: $hasReadPrivacyPolicy,
                            isRequired: true
                        )
                        
                        ConsentToggle(
                            title: "Kullanım Şartlarını Kabul Ediyorum",
                            description: "Uygulama kullanım koşullarını kabul edin",
                            isOn: $hasReadTerms,
                            isRequired: true
                        )
                        
                        ConsentToggle(
                            title: "Kişisel Verilerimin İşlenmesine İzin Veriyorum",
                            description: "Sipariş ve teslimat işlemleri için gerekli",
                            isOn: $allowsDataProcessing,
                            isRequired: true
                        )
                    }
                    .padding()
                    
                    Divider()
                    
                    // İsteğe Bağlı Rızalar
                    VStack(alignment: .leading, spacing: 16) {
                        Text("İsteğe Bağlı Rızalar")
                            .font(.headline)
                        
                        ConsentToggle(
                            title: "Konum Bilgilerimin Kullanılması",
                            description: "Daha iyi teslimat deneyimi için",
                            isOn: $allowsLocationTracking,
                            isRequired: false
                        )
                        
                        ConsentToggle(
                            title: "Pazarlama İletişimi",
                            description: "Kampanya ve fırsatlardan haberdar olun",
                            isOn: $allowsMarketing,
                            isRequired: false
                        )
                    }
                    .padding()
                    
                    Divider()
                    
                    // Haklar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("KVKK Kapsamındaki Haklarınız")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            RightItem(text: "Kişisel verilerinizin işlenip işlenmediğini öğrenme")
                            RightItem(text: "İşlenmişse buna ilişkin bilgi talep etme")
                            RightItem(text: "İşlenme amacını öğrenme")
                            RightItem(text: "Eksik veya yanlış işlenmişse düzeltilmesini isteme")
                            RightItem(text: "Silinmesini veya yok edilmesini isteme")
                            RightItem(text: "Aktarıldığı 3. kişilere bildirilmesini isteme")
                        }
                        .padding(.leading)
                    }
                    .padding()
                    
                    // İletişim
                    VStack(alignment: .leading, spacing: 8) {
                        Text("İletişim")
                            .font(.headline)
                        
                        Text("KVKK ile ilgili sorularınız için:")
                            .font(.subheadline)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("kvkk@benimsehrim.com")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Accept Button
                    Button(action: {
                        if canAccept {
                            saveConsents()
                            onAccept()
                            dismiss()
                        }
                    }) {
                        Text("Kabul Et ve Devam Et")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canAccept ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!canAccept)
                    .padding()
                }
            }
            .navigationTitle("KVKK Aydınlatma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canAccept: Bool {
        hasReadPrivacyPolicy && hasReadTerms && allowsDataProcessing
    }
    
    private func saveConsents() {
        UserDefaults.standard.set(true, forKey: "kvkk_consent_given")
        UserDefaults.standard.set(hasReadPrivacyPolicy, forKey: "privacy_policy_read")
        UserDefaults.standard.set(hasReadTerms, forKey: "terms_accepted")
        UserDefaults.standard.set(allowsDataProcessing, forKey: "data_processing_allowed")
        UserDefaults.standard.set(allowsLocationTracking, forKey: "location_tracking_allowed")
        UserDefaults.standard.set(allowsMarketing, forKey: "marketing_allowed")
        UserDefaults.standard.set(Date(), forKey: "kvkk_consent_date")
    }
}

// MARK: - Consent Toggle

struct ConsentToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let isRequired: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle(isOn: $isOn) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if isRequired {
                                Text("*")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Right Item

struct RightItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - KVKK Manager

class KVKKManager {
    static let shared = KVKKManager()
    
    private init() {}
    
    var hasGivenConsent: Bool {
        return UserDefaults.standard.bool(forKey: "kvkk_consent_given")
    }
    
    var consentDate: Date? {
        return UserDefaults.standard.object(forKey: "kvkk_consent_date") as? Date
    }
    
    var allowsLocationTracking: Bool {
        return UserDefaults.standard.bool(forKey: "location_tracking_allowed")
    }
    
    var allowsMarketing: Bool {
        return UserDefaults.standard.bool(forKey: "marketing_allowed")
    }
    
    func revokeConsent() {
        UserDefaults.standard.set(false, forKey: "kvkk_consent_given")
        UserDefaults.standard.removeObject(forKey: "kvkk_consent_date")
    }
    
    func requestDataDeletion(completion: @escaping (Result<Void, Error>) -> Void) {
        // API call to request data deletion
        // This should trigger KVKK Article 7 rights
        Task {
            do {
                // TODO: Implement API call
                // try await SecureNetworkManager.shared.post(endpoint: "/user/delete-data", body: EmptyBody())
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Preview

struct KVKKConsentView_Previews: PreviewProvider {
    static var previews: some View {
        KVKKConsentView {
            print("Consent accepted")
        }
    }
}
