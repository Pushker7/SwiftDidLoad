import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    let code: String
    var colorHex: String
    var sharedCartId: String?
}

struct Product: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let unit: String
    let price: Int
    let mrp: Int
    let category: String
    let emoji: String
}

struct ProductCategory: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let emoji: String
}

struct SharedCartItem: Codable, Identifiable, Equatable {
    let productId: String
    var qty: Int
    let addedById: String
    let addedAt: Double
    var id: String { productId }
}

struct SharedCart: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var memberIds: [String]
    var items: [SharedCartItem]
}

struct PersonalCartItem: Codable, Identifiable, Equatable {
    let productId: String
    var qty: Int
    var id: String { productId }
}

struct ProductsResponse: Codable {
    let categories: [ProductCategory]
    let products: [Product]
}

struct UserResponse: Codable {
    let user: User
}

struct ConnectResponse: Codable {
    let user: User
    let cart: SharedCart
    let members: [User]
}

struct CartResponse: Codable {
    let cart: SharedCart
    let members: [User]
}

struct APIErrorBody: Codable {
    let error: String
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
}
