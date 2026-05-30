import ArgumentParser
import Foundation

enum NotificationSound: Codable, Equatable {
    case `default`
    case none
    case named(String)

    var rawValue: String {
        switch self {
        case .default: return "default"
        case .none: return "none"
        case .named(let name): return name
        }
    }
}

extension NotificationSound: ExpressibleByArgument {
    init?(argument: String) {
        switch argument.lowercased() {
        case "default": self = .default
        case "none": self = .none
        default: self = .named(argument)
        }
    }
}

extension NotificationSound {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "default": self = .default
        case "none": self = .none
        default: self = .named(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
