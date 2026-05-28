import AppKit
import ArgumentParser
import Foundation
@preconcurrency import UserNotifications

@main
struct Notify: AsyncParsableCommand {
    static let appVersion = "0.2.0"

    static let configuration = CommandConfiguration(
        commandName: "notify",
        abstract: "Send and manage native macOS notifications.",
        version: appVersion,
        subcommands: [
            StatusCommand.self,
            RequestPermissionCommand.self,
            SendCommand.self,
            UpdateCommand.self,
            DismissCommand.self,
            ListCommand.self,
            GetCommand.self,
            TestCommand.self,
            ListenCommand.self,
            AgentCommand.self,
            VersionCommand.self
        ]
    )

    @MainActor
    mutating func run() async throws {
        let center = UNUserNotificationCenter.current()
        let handler = NotificationResponseHandler()
        center.delegate = handler

        let deadline = Date(timeIntervalSinceNow: 2)
        while !handler.done && RunLoop.current.run(mode: .default, before: deadline) {}

        if let response = handler.response {
            let action = response.actionIdentifier
            let urlString = response.notification.request.content.userInfo["url"] as? String
            if (action == UNNotificationDefaultActionIdentifier || action == NotifyAction.open.rawValue),
               let urlString, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        } else {
            throw CleanExit.helpRequest(self)
        }
    }
}
