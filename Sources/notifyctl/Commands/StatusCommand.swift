import ArgumentParser

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show macOS notification permission state."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("status not implemented yet")
    }
}
