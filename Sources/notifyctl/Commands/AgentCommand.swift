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

    @OptionGroup var output: OutputOptions

    mutating func run() throws {
        do {
            let plistURL = launchAgentURL()
            let logURL = listenerLogURL()
            let label = "io.notifyctl.listener"
            let executablePath = Bundle.main.executablePath ?? "/usr/local/bin/notifyctl"

            if output.dryRun {
                let result = AgentInstallResult(
                    plistPath: plistURL.path,
                    logPath: logURL.path,
                    label: label
                )
                if output.json {
                    try CommandOutput.success(
                        command: "agent.install",
                        status: "dry_run",
                        data: result,
                        json: true,
                        quiet: output.quiet
                    )
                } else if !output.quiet {
                    print("dry-run: install LaunchAgent")
                }
                return
            }

            try FileManager.default.createDirectory(
                at: logURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let plist: [String: Any] = [
                "Label": label,
                "ProgramArguments": [executablePath, "listen"],
                "RunAtLoad": true,
                "KeepAlive": true,
                "StandardOutPath": logURL.path,
                "StandardErrorPath": logURL.path
            ]

            let plistData = try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )
            try plistData.write(to: plistURL)

            let (_, stderr, statusCode) = try runProcess(
                executable: "/bin/launchctl",
                arguments: ["load", plistURL.path]
            )
            if statusCode != 0 {
                throw NotifyCtlError.systemError(
                    message: "Failed to load LaunchAgent.",
                    detail: stderr.isEmpty
                        ? "launchctl exited with code \(statusCode)"
                        : stderr
                )
            }

            let result = AgentInstallResult(
                plistPath: plistURL.path,
                logPath: logURL.path,
                label: label
            )
            if output.json {
                try CommandOutput.success(
                    command: "agent.install",
                    status: "installed",
                    data: result,
                    json: true,
                    quiet: output.quiet
                )
            } else if !output.quiet {
                print("LaunchAgent installed and loaded.")
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(command: "agent.install", error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "agent.install",
                error: .systemError(
                    message: "Failed to install LaunchAgent.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

struct AgentUninstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Unload and remove the LaunchAgent."
    )

    @OptionGroup var output: OutputOptions

    mutating func run() throws {
        do {
            let plistURL = launchAgentURL()
            let installed = FileManager.default.fileExists(atPath: plistURL.path)

            if output.dryRun {
                let result = AgentUninstallResult(wasInstalled: installed, removed: installed)
                if output.json {
                    try CommandOutput.success(
                        command: "agent.uninstall",
                        status: "dry_run",
                        data: result,
                        json: true,
                        quiet: output.quiet
                    )
                } else if !output.quiet {
                    print("dry-run: uninstall LaunchAgent")
                }
                return
            }

            if installed {
                let (_, stderr, statusCode) = try runProcess(
                    executable: "/bin/launchctl",
                    arguments: ["unload", plistURL.path]
                )
                if statusCode != 0 {
                    throw NotifyCtlError.systemError(
                        message: "Failed to unload LaunchAgent.",
                        detail: stderr.isEmpty
                            ? "launchctl exited with code \(statusCode)"
                            : stderr
                    )
                }

                try FileManager.default.removeItem(at: plistURL)

                let result = AgentUninstallResult(wasInstalled: true, removed: true)
                if output.json {
                    try CommandOutput.success(
                        command: "agent.uninstall",
                        status: "uninstalled",
                        data: result,
                        json: true,
                        quiet: output.quiet
                    )
                } else if !output.quiet {
                    print("LaunchAgent unloaded and removed.")
                }
            } else {
                let result = AgentUninstallResult(wasInstalled: false, removed: false)
                if output.json {
                    try CommandOutput.success(
                        command: "agent.uninstall",
                        status: "not_installed",
                        data: result,
                        json: true,
                        quiet: output.quiet
                    )
                } else if !output.quiet {
                    print("No LaunchAgent found.")
                }
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(command: "agent.uninstall", error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "agent.uninstall",
                error: .systemError(
                    message: "Failed to uninstall LaunchAgent.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

struct AgentStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check if the listener LaunchAgent is installed and running."
    )

    @OptionGroup var output: OutputOptions

    mutating func run() throws {
        do {
            let plistURL = launchAgentURL()
            let label = "io.notifyctl.listener"
            let installed = FileManager.default.fileExists(atPath: plistURL.path)
            let logURL = listenerLogURL()

            let (stdout, _, statusCode) = try runProcess(
                executable: "/bin/launchctl",
                arguments: ["print", "gui/\(getuid())/\(label)"]
            )
            let serviceState: AgentServiceState
            if statusCode == 0 {
                serviceState = stdout.contains("state = running") ? .running : .loaded
            } else {
                serviceState = .notLoaded
            }

            let result = AgentStatusResult(
                plistInstalled: installed,
                serviceState: serviceState.rawValue,
                label: label,
                plistPath: plistURL.path,
                logPath: logURL.path
            )

            if output.json {
                try CommandOutput.success(
                    command: "agent.status",
                    status: "ok",
                    data: result,
                    json: true,
                    quiet: output.quiet
                )
                return
            }

            if output.quiet {
                return
            }

            print("Plist: \(installed ? "installed" : "not installed")")
            print("Service: \(serviceState.displayValue)")
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(command: "agent.status", error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "agent.status",
                error: .systemError(
                    message: "Failed to read LaunchAgent status.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

private func launchAgentURL() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/io.notifyctl.listener.plist")
}

private func listenerLogURL() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/notifyctl/listener.log")
}

private func runProcess(
    executable: String,
    arguments: [String]
) throws -> (stdout: String, stderr: String, statusCode: Int32) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return (stdout: stdout, stderr: stderr, statusCode: process.terminationStatus)
}

private enum AgentServiceState: String {
    case running = "running"
    case loaded = "loaded"
    case notLoaded = "not_loaded"

    var displayValue: String {
        switch self {
        case .running:
            return "running"
        case .loaded:
            return "loaded"
        case .notLoaded:
            return "not loaded"
        }
    }
}

private struct AgentInstallResult: Codable {
    let plistPath: String
    let logPath: String
    let label: String

    enum CodingKeys: String, CodingKey {
        case plistPath = "plist_path"
        case logPath = "log_path"
        case label
    }
}

private struct AgentUninstallResult: Codable {
    let wasInstalled: Bool
    let removed: Bool

    enum CodingKeys: String, CodingKey {
        case wasInstalled = "was_installed"
        case removed
    }
}

private struct AgentStatusResult: Codable {
    let plistInstalled: Bool
    let serviceState: String
    let label: String
    let plistPath: String
    let logPath: String

    enum CodingKeys: String, CodingKey {
        case plistInstalled = "plist_installed"
        case serviceState = "service_state"
        case label
        case plistPath = "plist_path"
        case logPath = "log_path"
    }
}
