import ArgumentParser

struct GetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one notification by identifier."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("get not implemented yet")
    }
}
