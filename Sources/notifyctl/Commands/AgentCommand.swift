import ArgumentParser
import Foundation

struct AgentCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Manage the background notification listener.",
        subcommands: [
            AgentInstallCommand.self,
            AgentUninstallCommand.self,
            AgentStatusCommand.self
        ]
    )
}

struct AgentInstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install and load the LaunchAgent for background notification listening."
    )

    mutating func run() throws {
        let plistURL = launchAgentURL()
        let label = "io.notifyctl.listener"
        let executablePath = Bundle.main.executablePath ?? "/usr/local/bin/notifyctl"

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath, "listen"],
            "RunAtLoad": true,
            "KeepAlive": true,
            "StandardOutPath": "/tmp/notifyctl-listener.log",
            "StandardErrorPath": "/tmp/notifyctl-listener.log"
        ]

        let plistData = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try plistData.write(to: plistURL)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistURL.path]
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("LaunchAgent installed and loaded.")
        } else {
            throw NotifyCtlError.systemError(
                message: "Failed to load LaunchAgent.",
                detail: "launchctl exited with code \(process.terminationStatus)"
            )
        }
    }
}

struct AgentUninstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Unload and remove the LaunchAgent."
    )

    mutating func run() throws {
        let plistURL = launchAgentURL()

        if FileManager.default.fileExists(atPath: plistURL.path) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["unload", plistURL.path]
            try process.run()
            process.waitUntilExit()

            try FileManager.default.removeItem(at: plistURL)
            print("LaunchAgent unloaded and removed.")
        } else {
            print("No LaunchAgent found.")
        }
    }
}

struct AgentStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check if the listener LaunchAgent is installed and running."
    )

    mutating func run() throws {
        let plistURL = launchAgentURL()
        let label = "io.notifyctl.listener"

        if FileManager.default.fileExists(atPath: plistURL.path) {
            print("Plist: installed")
        } else {
            print("Plist: not installed")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["print", "gui/\(getuid())/\(label)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            if output.contains("state = running") {
                print("Service: running")
            } else {
                print("Service: loaded")
            }
        } else {
            print("Service: not loaded")
        }
    }
}

private func launchAgentURL() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/io.notifyctl.listener.plist")
}
