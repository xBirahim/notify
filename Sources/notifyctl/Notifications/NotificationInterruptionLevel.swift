import ArgumentParser
@preconcurrency import UserNotifications

enum InterruptionLevel: String, Codable, ExpressibleByArgument {
    case passive
    case active
    case timeSensitive = "time-sensitive"
}

extension InterruptionLevel {
    var systemValue: UNNotificationInterruptionLevel {
        switch self {
        case .passive:
            return .passive
        case .active:
            return .active
        case .timeSensitive:
            return .timeSensitive
        }
    }
}
