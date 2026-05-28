import ArgumentParser

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List notifications from local store."
    )

    @Option(help: "Filter by thread identifier.")
    var thread: String?

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let store = LocalStore()
            let records = store.listNotifications(thread: thread)

            if output.json {
                try CommandOutput.success(
                    command: "list",
                    status: "ok",
                    data: records,
                    json: true
                )
                return
            }

            if output.quiet {
                return
            }

            if records.isEmpty {
                print("(no notifications)")
            } else {
                for item in records {
                    let cat = item.category ?? "-"
                    let thr = item.thread ?? "-"
                    print("  \(item.id)  \(item.title)  \(item.body)  \(cat)  \(thr)")
                }
            }
        } catch let exit as ExitCode {
            throw exit
        } catch {
            try CommandOutput.failure(
                command: "list",
                error: .systemError(
                    message: "Failed to list notifications.",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}
