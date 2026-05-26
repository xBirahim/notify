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
        let event = ActionEvent(
            notificationId: response.notification.request.identifier,
            action: response.actionIdentifier,
            category: content.categoryIdentifier,
            url: content.userInfo["url"] as? String,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        try? store.appendAction(event)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(event),
           let json = String(data: data, encoding: .utf8) {
            print(json)
        }

        completionHandler()
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
