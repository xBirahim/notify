import CoreServices
import Foundation
@preconcurrency import UserNotifications

final class NotificationService {
    private let center: UNUserNotificationCenter
    private let store = LocalStore()

    init(center: UNUserNotificationCenter) {
        self.center = center
    }

    static func makeDefault() throws -> NotificationService {
        let bundlePath = Bundle.main.bundlePath
        let isAppBundle = bundlePath.hasSuffix(".app")
        if !isAppBundle {
            throw NotifyCtlError.systemError(
                message: "UserNotifications requires a macOS .app bundle.",
                detail: "Install notifyctl with: make install"
            )
        }
        LSRegisterURL(Bundle.main.bundleURL as CFURL, true)
        return NotificationService(center: .current())
    }

    func getStatus() async -> NotificationStatus {
        let settings = await notificationSettings()
        return NotificationStatus(settings: settings)
    }

    func requestPermission(options: UNAuthorizationOptions) async throws -> Bool {
        try await requestAuthorization(options: options)
    }

    func ensureCanSend() async throws {
        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return
        case .notDetermined:
            let granted = try? await requestAuthorization(options: .provisional)
            if granted == true { return }
            throw NotifyCtlError.permissionDenied(
                message: "Notifications are not authorized.",
                detail: "Run notifyctl request-permission to open System Settings."
            )
        case .denied:
            throw NotifyCtlError.permissionDenied(
                message: "Notifications are denied in macOS settings.",
                detail: "Enable notifications for notifyctl in System Settings -> Notifications."
            )
        @unknown default:
            throw NotifyCtlError.systemError(
                message: "Unknown notification authorization status.",
                detail: nil
            )
        }
    }

    func send(_ payload: NotificationPayload) async throws -> String {
        try await ensureCanSend()

        let identifier = payload.id ?? UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = payload.title ?? "notifyctl"
        content.subtitle = payload.subtitle ?? ""
        content.body = payload.body
        content.categoryIdentifier = payload.category ?? ""

        if payload.sound == .default {
            content.sound = .default
        }

        var userInfo: [AnyHashable: Any] = payload.userInfo
        userInfo["notifyctl"] = true

        if let url = payload.url {
            userInfo["url"] = url
        }

        content.userInfo = userInfo

        if let thread = payload.thread {
            content.threadIdentifier = thread
        }

        if let level = payload.interruptionLevel {
            content.interruptionLevel = level.systemValue
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        try await add(request)

        let now = ISO8601DateFormatter().string(from: Date())
        let existing = store.getNotification(id: identifier)
        let record = NotificationRecord(
            id: identifier,
            title: content.title,
            subtitle: content.subtitle,
            body: content.body,
            category: payload.category,
            thread: payload.thread,
            url: payload.url,
            createdAt: existing?.createdAt ?? now,
            updatedAt: existing != nil ? now : nil
        )
        do {
            try store.appendNotification(record)
        } catch {
            throw NotifyCtlError.systemError(
                message: "Notification delivered but failed to persist local record.",
                detail: String(describing: error)
            )
        }

        return identifier
    }

    func registerCategories() {
        let plain = UNNotificationCategory(
            identifier: NotifyCategory.plain.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let ack = UNNotificationAction(
            identifier: NotifyAction.acknowledge.rawValue,
            title: "Acknowledge",
            options: []
        )
        let open = UNNotificationAction(
            identifier: NotifyAction.open.rawValue,
            title: "Open",
            options: .foreground
        )
        let silence = UNNotificationAction(
            identifier: NotifyAction.silence.rawValue,
            title: "Silence",
            options: .destructive
        )

        let alert = UNNotificationCategory(
            identifier: NotifyCategory.alert.rawValue,
            actions: [ack, open, silence],
            intentIdentifiers: [],
            options: []
        )

        let retry = UNNotificationAction(
            identifier: NotifyAction.retry.rawValue,
            title: "Retry",
            options: []
        )

        let job = UNNotificationCategory(
            identifier: NotifyCategory.job.rawValue,
            actions: [ack, retry, open],
            intentIdentifiers: [],
            options: []
        )

        let rollback = UNNotificationAction(
            identifier: NotifyAction.rollback.rawValue,
            title: "Rollback",
            options: .destructive
        )

        let deploy = UNNotificationCategory(
            identifier: NotifyCategory.deploy.rawValue,
            actions: [open, rollback, ack],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([plain, alert, job, deploy])
    }

    func dismiss(
        ids: [String],
        removePending: Bool = true,
        removeDelivered: Bool = true
    ) {
        if removeDelivered {
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }

        if removePending {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func dismissAll(removePending: Bool = true, removeDelivered: Bool = true) {
        if removeDelivered {
            center.removeAllDeliveredNotifications()
        }

        if removePending {
            center.removeAllPendingNotificationRequests()
        }
    }
}

private extension NotificationService {
    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }
}
