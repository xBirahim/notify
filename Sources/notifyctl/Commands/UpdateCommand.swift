import ArgumentParser

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a notification by replacing it."
    )

    @Argument(help: "Notification identifier.")
    var id: String

    @Option(help: "Notification title.")
    var title: String?

    @Option(help: "Notification subtitle.")
    var subtitle: String?

    @Option(help: "Notification message.")
    var message: String?

    @Option(help: "Logical notification level.")
    var level: NotificationLevel?

    @Option(help: "Logical notification group.")
    var group: String?

    @Option(help: "Sound type.")
    var sound: NotificationSound?

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let service = try NotificationService.makeDefault()
            guard let existing = await service.get(id: id) else {
                throw NotifyCtlError.notFound(
                    message: "Notification not found.",
                    detail: "No pending or delivered notification with id '\(id)'."
                )
            }

            let payload = NotificationPayload(
                id: id,
                title: title ?? nonEmpty(existing.title),
                subtitle: subtitle ?? nonEmpty(existing.subtitle),
                message: message ?? existing.message,
                level: level ?? existing.level ?? .info,
                group: group ?? existing.group,
                sound: sound ?? .default,
                thread: group ?? existing.group,
                category: nil,
                url: nil,
                userInfo: [:]
            )

            if output.dryRun {
                let dry = UpdateResult(message: payload.message, level: payload.level, group: payload.group)
                if output.json {
                    try CommandOutput.success(
                        command: "update",
                        id: id,
                        status: "dry_run",
                        data: dry,
                        json: true
                    )
                } else if !output.quiet {
                    print("dry-run: update \(id)")
                }
                return
            }

            service.dismiss(ids: [id], removePending: true, removeDelivered: true)
            _ = try await service.send(payload)

            let result = UpdateResult(
                message: payload.message,
                level: payload.level,
                group: payload.group
            )

            if output.json {
                try CommandOutput.success(
                    command: "update",
                    id: id,
                    status: "updated",
                    data: result,
                    json: true
                )
            } else if !output.quiet {
                print("updated: \(id)")
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(command: "update", id: id, error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "update",
                id: id,
                error: .systemError(
                    message: "Failed to update notification.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

private extension UpdateCommand {
    func nonEmpty(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}

private struct UpdateResult: Codable {
    let message: String
    let level: NotificationLevel
    let group: String?
}
