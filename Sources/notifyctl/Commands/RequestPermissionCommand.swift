import ArgumentParser

struct RequestPermissionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "request-permission",
        abstract: "Request macOS notification authorization."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("request-permission not implemented yet")
    }
}
