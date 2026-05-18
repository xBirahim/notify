import ArgumentParser

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List pending and delivered notifications."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("list not implemented yet")
    }
}
