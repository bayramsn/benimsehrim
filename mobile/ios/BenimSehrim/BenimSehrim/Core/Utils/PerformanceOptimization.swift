import SwiftUI

/// Performance optimized image view with caching
struct OptimizedAsyncImage: View {
    let url: String
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
                    .resizable()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            image = try await SecureNetworkManager.shared.loadImage(from: url)
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}

// MARK: - List Performance Optimization

extension View {
    /// Optimize list performance with lazy loading
    func optimizedForList() -> some View {
        self
            .drawingGroup() // Render off-screen for better performance
    }
}

// MARK: - Memory Management

class MemoryWarningHandler: ObservableObject {
    static let shared = MemoryWarningHandler()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // Clear image cache
        ImageCache.shared.clear()
        
        // Post notification for ViewModels to clean up
        NotificationCenter.default.post(
            name: .memoryWarning,
            object: nil
        )
    }
}

extension Notification.Name {
    static let memoryWarning = Notification.Name("memoryWarning")
}

// MARK: - Lazy Loading Helper

struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}
