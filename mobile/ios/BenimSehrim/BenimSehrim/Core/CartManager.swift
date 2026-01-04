import Foundation
import Combine

class CartManager: ObservableObject {
    static let shared = CartManager()
    
    @Published var items: [Product: Int] = [:]
    
    var total: Double {
        items.reduce(0) { $0 + ($1.key.price * Double($1.value)) }
    }
    
    var itemCount: Int {
        items.values.reduce(0, +)
    }
    
    func addToCart(_ product: Product) {
        if let count = items[product] {
            items[product] = count + 1
        } else {
            items[product] = 1
        }
    }
    
    func removeFromCart(_ product: Product) {
        if let count = items[product], count > 1 {
            items[product] = count - 1
        } else {
            items.removeValue(forKey: product)
        }
    }
    
    func clear() {
        items.removeAll()
    }
}

// Enable Product as Dictionary Key
extension Product: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
}
