import ArgumentParser

struct DismissCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dismiss",
        abstract: "Dismiss pending and/or delivered notifications."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("dismiss not implemented yet")
    }
}
