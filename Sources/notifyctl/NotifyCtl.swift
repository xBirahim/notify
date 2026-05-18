import ArgumentParser
import Foundation

@main
struct NotifyCtl: AsyncParsableCommand {
    static let appVersion = "0.1.0"

    static let configuration = CommandConfiguration(
        commandName: "notifyctl",
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
            VersionCommand.self
        ]
    )
}
