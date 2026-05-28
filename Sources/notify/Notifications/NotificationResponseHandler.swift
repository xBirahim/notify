import AppKit
import Foundation
@preconcurrency import UserNotifications

final class NotificationResponseHandler: NSObject, UNUserNotificationCenterDelegate {
    private(set) var response: UNNotificationResponse?
    private(set) var done = false

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        self.response = response
        done = true
        completionHandler()
    }
}
