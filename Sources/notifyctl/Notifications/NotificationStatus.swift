import UserNotifications

struct NotificationStatus: Codable {
    let authorization: String
    let alerts: Bool
    let sounds: Bool
    let badges: Bool
}

extension NotificationStatus {
    init(settings: UNNotificationSettings) {
        authorization = settings.authorizationStatus.notifyctlValue
        alerts = settings.alertSetting == .enabled
        sounds = settings.soundSetting == .enabled
        badges = settings.badgeSetting == .enabled
    }
}

extension UNAuthorizationStatus {
    var notifyctlValue: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "ephemeral"
        @unknown default:
            return "unknown"
        }
    }
}
