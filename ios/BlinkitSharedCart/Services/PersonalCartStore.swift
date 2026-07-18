import Foundation

enum PersonalCartStore {
    private static let key = "personalCartItems"

    static func load() -> [PersonalCartItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([PersonalCartItem].self, from: data) else { return [] }
        return items
    }

    static func save(_ items: [PersonalCartItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
