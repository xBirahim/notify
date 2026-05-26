import ArgumentParser
import Foundation
@preconcurrency import UserNotifications

struct ListenCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listen",
        abstract: "Listen for notification actions (long-running process)."
    )

    mutating func run() throws {
        let service = try NotificationService.makeDefault()
        service.registerCategories()

        let center = UNUserNotificationCenter.current()
        let listener = NotificationListener()
        center.delegate = listener

        dispatchMain()
    }
}
