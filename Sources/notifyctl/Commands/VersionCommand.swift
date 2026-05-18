import ArgumentParser

struct VersionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print notifyctl version."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("version not implemented yet")
    }
}
