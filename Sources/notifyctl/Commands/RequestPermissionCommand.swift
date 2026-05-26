import AppKit
import ArgumentParser
@preconcurrency import UserNotifications

struct RequestPermissionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "request-permission",
        abstract: "Request macOS notification authorization."
    )

    @OptionGroup
    var output: OutputOptions

    @Flag(help: "Request sound permission.")
    var sound: Bool = false

    @Flag(help: "Request badge permission.")
    var badge: Bool = false

    @Flag(help: "Request provisional permission.")
    var provisional: Bool = false

    @Flag(help: "Request critical alert permission.")
    var critical: Bool = false

    @Flag(help: .hidden)
    var relaunched: Bool = false

    mutating func run() async throws {
        if relaunched {
            await MainActor.run {
                if let policy = NSApplication.ActivationPolicy(rawValue: 3) {
                    NSApplication.shared.setActivationPolicy(policy)
                }
            }
        }
        do {
            let service = try NotificationService.makeDefault()
            var options: UNAuthorizationOptions = [.alert]
            if sound {
                options.insert(.sound)
            }
            if badge {
                options.insert(.badge)
            }
            if provisional {
                options.insert(.provisional)
            }
            if critical {
                options.insert(.criticalAlert)
            }

            let granted = try await service.requestPermission(options: options)
            let data = PermissionResult(granted: granted)

            if output.json {
                try CommandOutput.success(
                    command: "request-permission",
                    status: granted ? "granted" : "denied",
                    data: data,
                    json: true
                )
            } else if !output.quiet {
                print("granted: \(granted)")
            }

            if !granted {
                throw ExitCode(.permissionDenied)
            }
        } catch let error as NSError where error.domain == UNErrorDomain && error.code == 1 {
            guard !relaunched else {
                try CommandOutput.failure(
                    command: "request-permission",
                    error: .systemError(
                        message: "Cannot request permissions from command line.",
                        detail: "Go to System Settings -> Notifications to enable notifications for NotifyCtl."
                    ),
                    json: output.json
                )
            }
            if !output.quiet {
                print("Opening System Settings and relaunching to request permission...")
            }
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = [
                Bundle.main.bundleURL.path,
                "--args", "request-permission", "--relaunched"
            ]
            try task.run()
            if !output.quiet {
                print("A permission dialog should appear shortly. Grant access to enable notifications.")
            }
            throw ExitCode(.success)
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(
                command: "request-permission",
                error: error,
                json: output.json
            )
        } catch {
            try CommandOutput.failure(
                command: "request-permission",
                error: .systemError(
                    message: "Unable to request notification permissions.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

private struct PermissionResult: Codable {
    let granted: Bool
}
