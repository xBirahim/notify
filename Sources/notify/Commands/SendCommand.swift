import AppKit
import ArgumentParser
import Foundation
@preconcurrency import UserNotifications

struct SendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification."
    )

    @Argument(help: "Notification body text.")
    var bodyArgument: String?

    @Option(help: "Notification identifier.")
    var id: String?

    @Option(help: "Notification title.")
    var title: String?

    @Option(help: "Notification subtitle.")
    var subtitle: String?

    @Option(help: "Notification body. Overrides positional body.")
    var body: String?

    @Option(help: "Category: plain, alert, job, deploy.")
    var category: NotifyCategory?

    @Option(help: "Thread identifier for macOS grouping.")
    var thread: String?

    @Option(help: "URL to attach.")
    var url: String?

    @Option(help: "Sound type.")
    var sound: NotificationSound = .default

    @Option(help: "Interruption level: passive, active.")
    var interruptionLevel: InterruptionLevel?

    @Option(help: "Additional user-info entry as key=value. Repeat for multiple entries.")
    var userInfo: [String] = []

    @Flag(help: "Wait for the user to respond to an action button.")
    var wait: Bool = false

    @Option(name: .customLong("wait-timeout"), help: "Maximum seconds to wait for a response (default: 120, 0 = no timeout).")
    var waitTimeout: Int = 120

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let payload = try buildPayload()
            let payloadID = payload.id

            if output.dryRun {
                let dryResult = SendResult(
                    title: payload.title ?? "notify",
                    body: payload.body,
                    category: payload.category,
                    interruptionLevel: payload.interruptionLevel?.rawValue
                )
                if output.json {
                    try CommandOutput.success(
                        command: "send",
                        id: payloadID,
                        status: "dry_run",
                        data: dryResult,
                        json: true
                    )
                } else if !output.quiet {
                    print("dry-run: send \(payloadID ?? "<generated-id>")")
                }
                return
            }

            let service = try NotificationService.makeDefault()
            service.registerCategories()
            let deliveredID = try await service.send(payload)

            if wait {
                try await waitForAction(id: deliveredID, payload: payload)
            } else {
                let result = SendResult(
                    title: payload.title ?? "notify",
                    body: payload.body,
                    category: payload.category,
                    interruptionLevel: payload.interruptionLevel?.rawValue
                )

                if output.json {
                    try CommandOutput.success(
                        command: "send",
                        id: deliveredID,
                        status: "delivered",
                        data: result,
                        json: true
                    )
                } else if !output.quiet {
                    print("sent: \(deliveredID)")
                }
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyError {
            try CommandOutput.failure(
                command: "send",
                id: id,
                error: error,
                json: output.json
            )
        } catch {
            try CommandOutput.failure(
                command: "send",
                id: id,
                error: .systemError(
                    message: "Failed to send notification.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

private extension SendCommand {
    func buildPayload() throws -> NotificationPayload {
        let resolvedBody = (body ?? bodyArgument ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedBody.isEmpty {
            throw NotifyError.invalidInput(
                message: "A notification body is required.",
                detail: "Provide a positional body or --body."
            )
        }

        let parsedUserInfo = try UserInfoParser.parse(userInfo)

        return NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            body: resolvedBody,
            sound: sound,
            thread: thread,
            category: category?.rawValue,
            url: url,
            interruptionLevel: interruptionLevel,
            userInfo: parsedUserInfo
        )
    }

    @MainActor
    func waitForAction(id: String, payload: NotificationPayload) async throws {
        let center = UNUserNotificationCenter.current()
        let waiter = WaitDelegate()
        center.delegate = waiter

        let timeoutNs = UInt64(max(0, waitTimeout)) * 1_000_000_000

        let event: ActionEvent = await withTaskGroup(of: ActionEvent?.self) { group in
            group.addTask {
                await waiter.wait()
            }

            if waitTimeout > 0 {
                group.addTask {
                    try? await Task.sleep(nanoseconds: timeoutNs)
                    return nil
                }
            }

            let result = await group.next() ?? nil
            group.cancelAll()

            if let event = result {
                return event
            }
            return ActionEvent(
                notificationId: id,
                action: "timeout",
                category: payload.category ?? "",
                url: payload.url,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }

        if event.action == UNNotificationDefaultActionIdentifier || event.action == NotifyAction.open.rawValue {
            if let urlString = event.url, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }

        let status = event.action == "timeout" ? "timeout" : event.action.lowercased()
        let data = ActionEvent(
            notificationId: event.notificationId,
            action: event.action,
            category: event.category,
            url: event.url,
            timestamp: event.timestamp
        )

        if output.json {
            try CommandOutput.success(
                command: "send",
                id: id,
                status: status,
                data: data,
                json: true
            )
        } else if !output.quiet {
            print("action: \(event.action)")
        }
    }
}

private final class WaitDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<ActionEvent, Never>?
    private let lock = NSLock()

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

        try? LocalStore().appendAction(event)

        lock.lock()
        continuation?.resume(returning: event)
        continuation = nil
        lock.unlock()

        completionHandler()
    }

    func wait() async -> ActionEvent {
        await withCheckedContinuation { continuation in
            lock.lock()
            self.continuation = continuation
            lock.unlock()
        }
    }
}

private struct SendResult: Codable {
    let title: String
    let body: String
    let category: String?
    let interruptionLevel: String?
}
