import Foundation

enum APIError: LocalizedError {
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .decoding: return "Something went wrong."
        }
    }
}

enum APIClient {
    private static let categoriesData = [
        ProductCategory(id: "dairy", label: "Dairy & Breakfast", emoji: "🥛"),
        ProductCategory(id: "fruits", label: "Fruits & Vegetables", emoji: "🍌"),
        ProductCategory(id: "snacks", label: "Munchies & Snacks", emoji: "🍿"),
        ProductCategory(id: "drinks", label: "Cold Drinks & Juices", emoji: "🥤"),
        ProductCategory(id: "instant", label: "Instant & Frozen Food", emoji: "🍜"),
        ProductCategory(id: "atta", label: "Atta, Rice & Dal", emoji: "🌾"),
        ProductCategory(id: "personal", label: "Personal Care", emoji: "🧴"),
        ProductCategory(id: "home", label: "Home & Cleaning", emoji: "🧹")
    ]

    private static let productsData = [
        Product(id: "p1", name: "Amul Toned Milk", unit: "1 L", price: 56, mrp: 60, category: "dairy", emoji: "🥛"),
        Product(id: "p2", name: "Harvest Gold Bread", unit: "500 g", price: 38, mrp: 38, category: "dairy", emoji: "🍞"),
        Product(id: "p3", name: "Eggs - Regular", unit: "Pack of 12", price: 66, mrp: 66, category: "dairy", emoji: "🥚"),
        Product(id: "p4", name: "Banana", unit: "1 kg", price: 42, mrp: 50, category: "fruits", emoji: "🍌"),
        Product(id: "p5", name: "Maggi 2-Minute Noodles", unit: "Pack of 4", price: 52, mrp: 56, category: "instant", emoji: "🍜"),
        Product(id: "p6", name: "Amul Butter", unit: "100 g", price: 62, mrp: 62, category: "dairy", emoji: "🧈"),
        Product(id: "p7", name: "Curd (Amul Masti)", unit: "400 g", price: 35, mrp: 40, category: "dairy", emoji: "🥣"),
        Product(id: "p8", name: "Paneer", unit: "200 g", price: 89, mrp: 95, category: "dairy", emoji: "🧀"),
        Product(id: "p9", name: "Onion", unit: "1 kg", price: 34, mrp: 40, category: "fruits", emoji: "🧅"),
        Product(id: "p10", name: "Tomato", unit: "500 g", price: 22, mrp: 28, category: "fruits", emoji: "🍅"),
        Product(id: "p11", name: "Potato", unit: "1 kg", price: 30, mrp: 35, category: "fruits", emoji: "🥔"),
        Product(id: "p12", name: "Apple (Shimla)", unit: "4 pcs", price: 96, mrp: 110, category: "fruits", emoji: "🍎"),
        Product(id: "p13", name: "Coriander", unit: "100 g", price: 12, mrp: 15, category: "fruits", emoji: "🌿"),
        Product(id: "p14", name: "Lay's Magic Masala", unit: "82 g", price: 20, mrp: 20, category: "snacks", emoji: "🥔"),
        Product(id: "p15", name: "Kurkure Masala Munch", unit: "90 g", price: 20, mrp: 20, category: "snacks", emoji: "🌽"),
        Product(id: "p16", name: "Parle-G Gold", unit: "1 kg", price: 95, mrp: 100, category: "snacks", emoji: "🍪"),
        Product(id: "p17", name: "Dark Fantasy Choco Fills", unit: "300 g", price: 110, mrp: 120, category: "snacks", emoji: "🍫"),
        Product(id: "p18", name: "Haldiram Bhujia", unit: "200 g", price: 55, mrp: 60, category: "snacks", emoji: "🥨"),
        Product(id: "p19", name: "Coca-Cola", unit: "750 ml", price: 40, mrp: 45, category: "drinks", emoji: "🥤"),
        Product(id: "p20", name: "Sprite", unit: "750 ml", price: 40, mrp: 45, category: "drinks", emoji: "🍋"),
        Product(id: "p21", name: "Real Mixed Fruit Juice", unit: "1 L", price: 110, mrp: 125, category: "drinks", emoji: "🧃"),
        Product(id: "p22", name: "Bisleri Water", unit: "1 L", price: 20, mrp: 22, category: "drinks", emoji: "💧"),
        Product(id: "p23", name: "Amul Kool Coffee", unit: "200 ml", price: 25, mrp: 30, category: "drinks", emoji: "☕"),
        Product(id: "p24", name: "Frozen French Fries", unit: "400 g", price: 99, mrp: 120, category: "instant", emoji: "🍟"),
        Product(id: "p25", name: "Momos (Veg, Frozen)", unit: "300 g", price: 105, mrp: 115, category: "instant", emoji: "🥟"),
        Product(id: "p26", name: "Knorr Soup - Sweet Corn", unit: "44 g", price: 35, mrp: 40, category: "instant", emoji: "🥣"),
        Product(id: "p27", name: "Aashirvaad Atta", unit: "5 kg", price: 245, mrp: 270, category: "atta", emoji: "🌾"),
        Product(id: "p28", name: "India Gate Basmati Rice", unit: "1 kg", price: 120, mrp: 140, category: "atta", emoji: "🍚"),
        Product(id: "p29", name: "Toor Dal", unit: "1 kg", price: 145, mrp: 160, category: "atta", emoji: "🫘"),
        Product(id: "p30", name: "Fortune Sunflower Oil", unit: "1 L", price: 135, mrp: 150, category: "atta", emoji: "🛢️"),
        Product(id: "p31", name: "Colgate MaxFresh", unit: "150 g", price: 92, mrp: 99, category: "personal", emoji: "🪥"),
        Product(id: "p32", name: "Dove Shampoo", unit: "340 ml", price: 210, mrp: 240, category: "personal", emoji: "🧴"),
        Product(id: "p33", name: "Dettol Handwash", unit: "200 ml", price: 75, mrp: 85, category: "personal", emoji: "🧼"),
        Product(id: "p34", name: "Nivea Body Lotion", unit: "200 ml", price: 165, mrp: 199, category: "personal", emoji: "🧴"),
        Product(id: "p35", name: "Surf Excel Liquid", unit: "1 L", price: 195, mrp: 220, category: "home", emoji: "🧺"),
        Product(id: "p36", name: "Vim Dishwash Gel", unit: "500 ml", price: 99, mrp: 115, category: "home", emoji: "🍽️"),
        Product(id: "p37", name: "Lizol Floor Cleaner", unit: "975 ml", price: 168, mrp: 189, category: "home", emoji: "🧹"),
        Product(id: "p38", name: "Garbage Bags (Medium)", unit: "30 pcs", price: 59, mrp: 70, category: "home", emoji: "🗑️")
    ]

    static func createUser(name: String) async throws -> User {
        let colors = ["#22C55E", "#3B82F6", "#A855F7", "#F59E0B", "#EF4444", "#06B6D4"]
        let randomColor = colors.randomElement() ?? "#22C55E"
        
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomCode = String((0..<6).map { _ in chars.randomElement()! })
        
        let newUser = User(
            id: UUID().uuidString,
            name: name,
            code: randomCode,
            colorHex: randomColor,
            sharedCartId: nil
        )
        
        if let encoded = try? JSONEncoder().encode(newUser) {
            UserDefaults.standard.set(encoded, forKey: "localUser")
        }
        return newUser
    }

    static func fetchUser(id: String) async throws -> User {
        guard let data = UserDefaults.standard.data(forKey: "localUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            throw APIError.server("User not found")
        }
        return user
    }

    static func fetchProducts() async throws -> ProductsResponse {
        return ProductsResponse(categories: categoriesData, products: productsData)
    }

    static func connect(userId: String, code: String) async throws -> ConnectResponse {
        throw APIError.server("P2P matching should bypass HTTP API connection.")
    }

    static func fetchCart(id: String) async throws -> CartResponse {
        throw APIError.server("P2P synchronization handles cart fetches.")
    }
}
