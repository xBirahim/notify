import ArgumentParser
import Foundation
@preconcurrency import UserNotifications

struct ListenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listen",
        abstract: "Listen for notification actions (long-running process)."
    )

    @MainActor
    mutating func run() async throws {
        let service = try NotificationService.makeDefault()
        service.registerCategories()

        let center = UNUserNotificationCenter.current()
        let listener = NotificationListener()
        center.delegate = listener

        await withUnsafeContinuation { (_: UnsafeContinuation<Void, Never>) in }
    }
}
