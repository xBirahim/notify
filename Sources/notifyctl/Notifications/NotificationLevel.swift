import ArgumentParser

enum NotificationLevel: String, Codable, ExpressibleByArgument {
    case info
    case success
    case warning
    case error
    case critical
}
