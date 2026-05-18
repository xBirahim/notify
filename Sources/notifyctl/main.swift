import ArgumentParser
import Foundation

@main
struct NotifyCtl: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notifyctl",
        abstract: "Send and manage native macOS notifications.",
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
