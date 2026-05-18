import ArgumentParser
import Foundation

struct SendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification."
    )

    @Argument(help: "Notification message.")
    var messageArgument: String?

    @Option(help: "Notification identifier.")
    var id: String?

    @Option(help: "Notification title.")
    var title: String?

    @Option(help: "Notification subtitle.")
    var subtitle: String?

    @Option(help: "Notification message. Overrides positional message.")
    var message: String?

    @Option(help: "Logical notification level.")
    var level: NotificationLevel = .info

    @Option(help: "Logical notification group.")
    var group: String?

    @Option(help: "Thread identifier.")
    var thread: String?

    @Option(help: "Category identifier.")
    var category: String?

    @Option(help: "Sound type.")
    var sound: NotificationSound = .default

    @Option(help: "URL to attach in userInfo.")
    var url: String?

    @Option(parsing: .upToNextOption, help: "Additional userInfo key=value entries.")
    var userInfo: [String] = []

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let payload = try buildPayload()
            let payloadID = payload.id

            if output.dryRun {
                let dryResult = SendResult(
                    title: payload.title ?? "notifyctl",
                    message: payload.message,
                    level: payload.level,
                    group: payload.group
                )
                if output.json {
                    try CommandOutput.success(
                        command: "send",
                        id: payloadID,
                        status: "dry_run",
                        data: dryResult,
                        json: true
                    )
                } else if !output.quiet {
                    print("dry-run: send \(payloadID ?? "<generated-id>")")
                }
                return
            }

            let service = try NotificationService.makeDefault()
            let deliveredID = try await service.send(payload)
            let result = SendResult(
                title: payload.title ?? "notifyctl",
                message: payload.message,
                level: payload.level,
                group: payload.group
            )

            if output.json {
                try CommandOutput.success(
                    command: "send",
                    id: deliveredID,
                    status: "delivered",
                    data: result,
                    json: true
                )
            } else if !output.quiet {
                print("sent: \(deliveredID)")
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(
                command: "send",
                id: id,
                error: error,
                json: output.json
            )
        } catch {
            try CommandOutput.failure(
                command: "send",
                id: id,
                error: .systemError(
                    message: "Failed to send notification.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

private extension SendCommand {
    func buildPayload() throws -> NotificationPayload {
        let resolvedMessage = (message ?? messageArgument ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedMessage.isEmpty {
            throw NotifyCtlError.invalidInput(
                message: "A notification message is required.",
                detail: "Provide a positional message or --message."
            )
        }

        return NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            message: resolvedMessage,
            level: level,
            group: group,
            sound: sound,
            thread: thread,
            category: category,
            url: url,
            userInfo: try UserInfoParser.parse(userInfo)
        )
    }
}

private struct SendResult: Codable {
    let title: String
    let message: String
    let level: NotificationLevel
    let group: String?
}
