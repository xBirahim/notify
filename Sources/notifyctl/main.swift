import ArgumentParser
import Foundation

@main
struct NotifyCtl: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notifyctl",
        abstract: "Send and manage native macOS notifications."
    )
}
