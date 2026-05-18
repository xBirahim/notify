import Foundation
@preconcurrency import UserNotifications

final class NotificationService {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter) {
        self.center = center
    }

    static func makeDefault() throws -> NotificationService {
        let bundlePath = Bundle.main.bundlePath
        if bundlePath.contains("/.build/") {
            throw NotifyCtlError.systemError(
                message: "UserNotifications is not available from this runtime context.",
                detail: "Build with swift build -c release and run the installed binary from a user session."
            )
        }
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
            throw NotifyCtlError.permissionDenied(
                message: "Notifications are not authorized.",
                detail: "Run notifyctl request-permission before send."
            )
        case .denied:
            throw NotifyCtlError.permissionDenied(
                message: "Notifications are denied in macOS settings.",
                detail: "Enable notifications for notifyctl in System Settings."
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
        content.body = payload.message
        content.categoryIdentifier = payload.category ?? ""

        if payload.sound == .default {
            content.sound = .default
        }

        var userInfo: [AnyHashable: Any] = payload.userInfo
        userInfo["notifyctl"] = true
        userInfo["level"] = payload.level.rawValue

        if let group = payload.group {
            userInfo["group"] = group
        }

        if let url = payload.url {
            userInfo["url"] = url
        }

        content.userInfo = userInfo

        if let thread = payload.thread ?? payload.group {
            content.threadIdentifier = thread
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        try await add(request)
        return identifier
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

    func dismissGroup(
        _ group: String,
        removePending: Bool = true,
        removeDelivered: Bool = true
    ) async -> [String] {
        let lists = await list(includePending: removePending, includeDelivered: removeDelivered, group: group)
        let deliveredIDs = lists.delivered.map(\.id)
        let pendingIDs = lists.pending.map(\.id)
        let ids = Array(Set(deliveredIDs + pendingIDs))
        dismiss(ids: ids, removePending: removePending, removeDelivered: removeDelivered)
        return ids
    }

    func list(
        includePending: Bool,
        includeDelivered: Bool,
        group: String?
    ) async -> NotificationListData {
        var delivered: [NotificationRecord] = []
        var pending: [NotificationRecord] = []

        if includeDelivered {
            delivered = await deliveredRecords()
        }

        if includePending {
            pending = await pendingRecords()
        }

        if let group {
            delivered = delivered.filter { $0.group == group }
            pending = pending.filter { $0.group == group }
        }

        return NotificationListData(delivered: delivered, pending: pending)
    }

    func get(id: String) async -> NotificationRecord? {
        let records = await list(includePending: true, includeDelivered: true, group: nil)
        if let delivered = records.delivered.first(where: { $0.id == id }) {
            return delivered
        }
        return records.pending.first(where: { $0.id == id })
    }
}

private extension NotificationService {
    static func record(id: String, state: String, content: UNNotificationContent) -> NotificationRecord {
        let level: NotificationLevel?
        if let raw = content.userInfo["level"] as? String {
            level = NotificationLevel(rawValue: raw)
        } else {
            level = nil
        }

        let group = content.userInfo["group"] as? String

        return NotificationRecord(
            id: id,
            state: state,
            title: content.title,
            subtitle: content.subtitle,
            message: content.body,
            level: level,
            group: group
        )
    }

    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    func deliveredRecords() async -> [NotificationRecord] {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                let records = notifications.map { notification in
                    Self.record(
                        id: notification.request.identifier,
                        state: "delivered",
                        content: notification.request.content
                    )
                }
                continuation.resume(returning: records)
            }
        }
    }

    func pendingRecords() async -> [NotificationRecord] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let records = requests.map { request in
                    Self.record(
                        id: request.identifier,
                        state: "pending",
                        content: request.content
                    )
                }
                continuation.resume(returning: records)
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
