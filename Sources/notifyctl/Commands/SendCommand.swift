import ArgumentParser
import Foundation

struct SendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification."
    )

    @Argument(help: "Notification body text.")
    var bodyArgument: String?

    @Option(help: "Notification identifier.")
    var id: String?

    @Option(help: "Notification title.")
    var title: String?

    @Option(help: "Notification subtitle.")
    var subtitle: String?

    @Option(help: "Notification body. Overrides positional body.")
    var body: String?

    @Option(help: "Category: plain, alert, job, deploy.")
    var category: NotifyCategory?

    @Option(help: "Thread identifier for macOS grouping.")
    var thread: String?

    @Option(help: "URL to attach.")
    var url: String?

    @Option(help: "Sound type.")
    var sound: NotificationSound = .default

    @Option(help: "Interruption level: passive, active.")
    var interruptionLevel: InterruptionLevel?

    @Option(help: "Additional user-info entry as key=value. Repeat for multiple entries.")
    var userInfo: [String] = []

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let payload = try buildPayload()
            let payloadID = payload.id

            if output.dryRun {
                let dryResult = SendResult(
                    title: payload.title ?? "notifyctl",
                    body: payload.body,
                    category: payload.category,
                    interruptionLevel: payload.interruptionLevel?.rawValue
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
                body: payload.body,
                category: payload.category,
                interruptionLevel: payload.interruptionLevel?.rawValue
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
        let resolvedBody = (body ?? bodyArgument ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedBody.isEmpty {
            throw NotifyCtlError.invalidInput(
                message: "A notification body is required.",
                detail: "Provide a positional body or --body."
            )
        }

        let parsedUserInfo = try UserInfoParser.parse(userInfo)

        return NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            body: resolvedBody,
            sound: sound,
            thread: thread,
            category: category?.rawValue,
            url: url,
            interruptionLevel: interruptionLevel,
            userInfo: parsedUserInfo
        )
    }
}

private struct SendResult: Codable {
    let title: String
    let body: String
    let category: String?
    let interruptionLevel: String?
}
