import ArgumentParser

struct OutputOptions: ParsableArguments {
    @Flag(help: "Print machine-readable JSON output.")
    var json: Bool = false

    @Flag(help: "Suppress non-error output.")
    var quiet: Bool = false

    @Flag(help: "Validate input without sending a notification.")
    var dryRun: Bool = false
}
