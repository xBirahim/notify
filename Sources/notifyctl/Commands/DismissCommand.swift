import ArgumentParser

struct DismissCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dismiss",
        abstract: "Dismiss pending and/or delivered notifications."
    )

    @Argument(help: "Notification identifier.")
    var idArgument: String?

    @Option(help: "Notification identifier.")
    var id: String?

    @Option(help: "Dismiss all notifications in this group.")
    var group: String?

    @Flag(help: "Dismiss all notifications owned by notifyctl.")
    var all: Bool = false

    @Flag(help: "Dismiss pending notifications.")
    var pending: Bool = false

    @Flag(help: "Dismiss delivered notifications.")
    var delivered: Bool = false

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        do {
            let target = try resolveTarget()
            let scope = resolveScope()

            if output.dryRun {
                let dry = DismissResult(
                    ids: target.id.map { [$0] },
                    group: target.group,
                    all: target.all,
                    pending: scope.pending,
                    delivered: scope.delivered
                )
                if output.json {
                    try CommandOutput.success(
                        command: "dismiss",
                        id: target.id,
                        status: "dry_run",
                        data: dry,
                        json: true
                    )
                } else if !output.quiet {
                    print("dry-run: dismiss")
                }
                return
            }

            let service = try NotificationService.makeDefault()
            var removedIDs: [String] = []
            if target.all {
                service.dismissAll(removePending: scope.pending, removeDelivered: scope.delivered)
            } else if let group = target.group {
                removedIDs = await service.dismissGroup(
                    group,
                    removePending: scope.pending,
                    removeDelivered: scope.delivered
                )
            } else if let id = target.id {
                removedIDs = [id]
                service.dismiss(ids: [id], removePending: scope.pending, removeDelivered: scope.delivered)
            }

            let result = DismissResult(
                ids: removedIDs.isEmpty ? nil : removedIDs,
                group: target.group,
                all: target.all,
                pending: scope.pending,
                delivered: scope.delivered
            )

            if output.json {
                try CommandOutput.success(
                    command: "dismiss",
                    id: target.id,
                    status: "dismissed",
                    data: result,
                    json: true
                )
            } else if !output.quiet {
                print("dismissed")
            }
        } catch let exit as ExitCode {
            throw exit
        } catch let error as NotifyCtlError {
            try CommandOutput.failure(
                command: "dismiss",
                id: id ?? idArgument,
                error: error,
                json: output.json
            )
        } catch {
            try CommandOutput.failure(
                command: "dismiss",
                id: id ?? idArgument,
                error: .systemError(
                    message: "Failed to dismiss notification(s).",
                    detail: String(describing: error)
                ),
                json: output.json
            )
        }
    }
}

private extension DismissCommand {
    struct DismissTarget {
        let id: String?
        let group: String?
        let all: Bool
    }

    struct DismissScope {
        let pending: Bool
        let delivered: Bool
    }

    func resolveTarget() throws -> DismissTarget {
        let resolvedID = id ?? idArgument
        let selectedModes = (resolvedID != nil ? 1 : 0) + (group != nil ? 1 : 0) + (all ? 1 : 0)
        if selectedModes == 0 {
            throw NotifyCtlError.invalidInput(
                message: "Dismiss target is required.",
                detail: "Provide an id, --group, or --all."
            )
        }
        if selectedModes > 1 {
            throw NotifyCtlError.invalidInput(
                message: "Dismiss options are mutually exclusive.",
                detail: "Use only one of id, --group, or --all."
            )
        }
        return DismissTarget(id: resolvedID, group: group, all: all)
    }

    func resolveScope() -> DismissScope {
        if !pending && !delivered {
            return DismissScope(pending: true, delivered: true)
        }
        return DismissScope(pending: pending, delivered: delivered)
    }
}

private struct DismissResult: Codable {
    let ids: [String]?
    let group: String?
    let all: Bool
    let pending: Bool
    let delivered: Bool
}
