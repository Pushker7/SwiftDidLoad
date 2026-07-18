import Foundation

enum AppConfig {
    // Simulator → Mac: "localhost". Physical iPhone → your Mac's LAN IP, e.g. "192.168.1.5".
    static let host = "localhost"
    static let port = 3001

    static var baseURL: URL { URL(string: "http://\(host):\(port)")! }
    static var wsURL: URL { URL(string: "ws://\(host):\(port)")! }
}
