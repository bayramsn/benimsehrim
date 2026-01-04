import SwiftUI

struct OrderSuccessView: View {
    @State private var scale: CGFloat = 0.5
    @State private var showContent = false
    @Environment(\.dismiss) var dismiss // To close fullscreen cover? No, we should navigate to root.
    
    // In iOS SwiftUI, navigating back to root Home is tricky with fullScreenCover.
    // We can use a shared navigation manager or just reset tabs.
    // For now, simpler navigation.
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Checkmark Animation
            ZStack {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                    scale = 1.0
                }
                withAnimation(.easeIn.delay(0.3)) {
                    showContent = true
                }
            }
            
            if showContent {
                VStack(spacing: 16) {
                    Text("Siparişiniz Alındı!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Siparişiniz başarıyla oluşturuldu ve mağazaya iletildi. Durumunu siparişlerim sayfasından takip edebilirsiniz.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                
                Spacer()
                
                // Buttons need to handle navigation properly
                // Usually we'd reset the Root TabView here.
                
                Button(action: {
                    // Navigate to Orders Tab (index 3)
                     // Since we don't have access to root TabView binding easily without EnvironmentObject,
                     // We will just dismiss for now, user is still in Checkout flow?
                     // Ideally we need NavigationPath or Tab selection management.
                     // Assuming Checkout was a fullScreenCover, dismissing it returns to Cart.
                     // But Cart should be empty now.
                     
                     // Best UX: Dismiss all presented views.
                     UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
                }) {
                    Text("Siparişlerime Git")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primaryGreen)
                        .cornerRadius(16)
                }
                
                Button(action: {
                     UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
                }) {
                    Text("Ana Sayfaya Dön")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            } else {
                Spacer()
            }
        }
        .padding(24)
    }
}

#Preview {
    OrderSuccessView()
}
