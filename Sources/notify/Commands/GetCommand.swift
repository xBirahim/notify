import ArgumentParser

struct GetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one notification by identifier."
    )

    @Argument(help: "Notification identifier.")
    var id: String

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let store = LocalStore()
            guard let record = store.getNotification(id: id) else {
                throw NotifyError.notFound(
                    message: "Notification not found.",
                    detail: nil
                )
            }

            if output.json {
                try CommandOutput.success(
                    command: "get",
                    id: id,
                    status: "found",
                    data: record,
                    json: true
                )
            } else if !output.quiet {
                let cat = record.category ?? "-"
                let thr = record.thread ?? "-"
                print("\(record.id) \(record.title) \(record.body) \(cat) \(thr)")
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyError {
            try CommandOutput.failure(command: "get", id: id, error: error, json: output.json)
        } catch {
            try CommandOutput.failure(
                command: "get",
                id: id,
                error: .systemError(
                    message: "Failed to get notification.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}
