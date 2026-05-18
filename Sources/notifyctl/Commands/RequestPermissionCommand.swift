import ArgumentParser
import UserNotifications

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

    mutating func run() async throws {
        let service = NotificationService()
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

        do {
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
        } catch let exit as ExitCode {
            throw exit
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
