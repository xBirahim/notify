import ArgumentParser

struct SendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification."
    )

    @OptionGroup
    var output: OutputOptions

    mutating func run() async throws {
        throw CleanExit.message("send not implemented yet")
    }
}
