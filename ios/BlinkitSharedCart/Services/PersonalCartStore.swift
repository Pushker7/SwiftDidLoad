import Foundation

enum PersonalCartStore {
    private static let key = "carts"

    static func load() -> [Cart] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let carts = try? JSONDecoder().decode([Cart].self, from: data) else { return [] }
        return carts
    }

    static func save(_ carts: [Cart]) {
        guard let data = try? JSONEncoder().encode(carts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
