import ArgumentParser

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List pending and delivered notifications."
    )

    @Flag(help: "Include pending notifications.")
    var pending: Bool = false

    @Flag(help: "Include delivered notifications.")
    var delivered: Bool = false

    @Option(help: "Filter by logical group.")
    var group: String?

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let includePending = pending || (!pending && !delivered)
            let includeDelivered = delivered || (!pending && !delivered)
            let service = try NotificationService.makeDefault()
            let result = await service.list(
                includePending: includePending,
                includeDelivered: includeDelivered,
                group: group
            )

            if output.json {
                try CommandOutput.success(
                    command: "list",
                    status: "ok",
                    data: result,
                    json: true
                )
                return
            }

            if output.quiet {
                return
            }

            if includeDelivered {
                print("DELIVERED")
                if result.delivered.isEmpty {
                    print("  (none)")
                } else {
                    for item in result.delivered {
                        let level = item.level?.rawValue ?? "-"
                        let group = item.group ?? "-"
                        print("  \(item.id)  \(item.title)  \(item.message)  \(level)  \(group)")
                    }
                }
                print("")
            }

            if includePending {
                print("PENDING")
                if result.pending.isEmpty {
                    print("  (none)")
                } else {
                    for item in result.pending {
                        let level = item.level?.rawValue ?? "-"
                        let group = item.group ?? "-"
                        print("  \(item.id)  \(item.title)  \(item.message)  \(level)  \(group)")
                    }
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
