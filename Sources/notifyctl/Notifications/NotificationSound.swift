import ArgumentParser

enum NotificationSound: String, Codable, ExpressibleByArgument {
    case `default`
    case none
}
