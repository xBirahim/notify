import ArgumentParser

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a notification by replacing it (same engine as send)."
    )

    @Argument(help: "Notification identifier.")
    var id: String

    @Option(help: "Notification title.")
    var title: String?

    @Option(help: "Notification subtitle.")
    var subtitle: String?

    @Option(help: "Notification body.")
    var body: String?

    @Option(help: "Category: plain, alert, job, deploy.")
    var category: NotifyCategory?

    @Option(help: "Thread identifier.")
    var thread: String?

    @Option(help: "URL to attach.")
    var url: String?

    @Option(help: "Interruption level: passive, active.")
    var interruptionLevel: InterruptionLevel?

    @Option(help: "Sound type.")
    var sound: NotificationSound = .default

    @Option(help: "Additional user-info entry as key=value. Repeat for multiple entries.")
    var userInfo: [String] = []

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let service = try NotificationService.makeDefault()
            let existing = LocalStore().getNotification(id: id)
            let parsedUserInfo = try UserInfoParser.parse(userInfo)

            let payload = NotificationPayload(
                id: id,
                title: title ?? existing?.title,
                subtitle: subtitle ?? existing?.subtitle,
                body: body ?? existing?.body ?? "",
                sound: sound,
                thread: thread ?? existing?.thread,
                category: category?.rawValue ?? existing?.category,
                url: url ?? existing?.url,
                interruptionLevel: interruptionLevel,
                userInfo: parsedUserInfo
            )

            if output.dryRun {
                let dry = UpdateResult(body: payload.body, category: payload.category, interruptionLevel: payload.interruptionLevel?.rawValue, sound: payload.sound.rawValue)
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

            _ = try await service.send(payload)
            let result = UpdateResult(body: payload.body, category: payload.category, interruptionLevel: payload.interruptionLevel?.rawValue, sound: payload.sound.rawValue)

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

private struct UpdateResult: Codable {
    let body: String
    let category: String?
    let interruptionLevel: String?
    let sound: String
}
