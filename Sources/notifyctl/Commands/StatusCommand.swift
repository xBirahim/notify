import ArgumentParser

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show macOS notification permission state."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        do {
            let service = try NotificationService.makeDefault()
            let status = await service.getStatus()

            if output.json {
                try CommandOutput.success(
                    command: "status",
                    status: "ok",
                    data: status,
                    json: true
                )
                return
            }

            if output.quiet {
                return
            }

            print("authorization: \(status.authorization)")
            print("alerts: \(status.alerts ? "enabled" : "disabled")")
            print("sounds: \(status.sounds ? "enabled" : "disabled")")
            print("badges: \(status.badges ? "enabled" : "disabled")")
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(command: "status", error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "status",
                error: .systemError(
                    message: "Failed to read notification status.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}
