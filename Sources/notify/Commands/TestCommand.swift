import ArgumentParser

struct TestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Send a test notification."
    )

    @Option(help: "Interruption level: passive, active.")
    var interruptionLevel: InterruptionLevel?

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        let payload = NotificationPayload(
            id: "notify-test",
            title: "notify",
            subtitle: nil,
            body: "Notification test",
            sound: .default,
            thread: "notify",
            category: nil,
            url: nil,
            interruptionLevel: interruptionLevel,
            userInfo: [:]
        )

        if output.dryRun {
            if output.json {
                try CommandOutput.success(
                    command: "test",
                    id: payload.id,
                    status: "dry_run",
                    data: EmptyData(),
                    json: true
                )
            } else if !output.quiet {
                print("dry-run: test notification")
            }
            return
        }

        do {
            let service = try NotificationService.makeDefault()
            let id = try await service.send(payload)
            if output.json {
                try CommandOutput.success(
                    command: "test",
                    id: id,
                    status: "delivered",
                    data: EmptyData(),
                    json: true
                )
            } else if !output.quiet {
                print("sent: \(id)")
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyError {
            try CommandOutput.failure(command: "test", id: payload.id, error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "test",
                id: payload.id,
                error: .systemError(
                    message: "Failed to send test notification.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}
