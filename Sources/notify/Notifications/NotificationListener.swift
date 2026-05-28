import AppKit
import Foundation
@preconcurrency import UserNotifications

final class NotificationListener: NSObject, UNUserNotificationCenterDelegate {
    private let store = LocalStore()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        let urlString = content.userInfo["url"] as? String
        
        let event = ActionEvent(
            notificationId: response.notification.request.identifier,
            action: response.actionIdentifier,
            category: content.categoryIdentifier,
            url: urlString,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        try? store.appendAction(event)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(event),
           let json = String(data: data, encoding: .utf8) {
            print(json)
        }

        // Si l'utilisateur clique sur la notification (default action) ou sur l'action "OPEN" et qu'une URL est présente, on l'ouvre
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier || response.actionIdentifier == NotifyAction.open.rawValue {
            if let urlString = urlString, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

struct ActionEvent: Codable {
    let notificationId: String
    let action: String
    let category: String
    let url: String?
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case notificationId = "notification_id"
        case action
        case category
        case url
        case timestamp
    }
}
