import ArgumentParser
import Foundation

struct VersionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print notifyctl version."
    )

    @OptionGroup var output: OutputOptions

    mutating func run() async throws {
        let data = VersionData(
            name: "notifyctl",
            version: NotifyCtl.appVersion,
            swift: swiftVersion(),
            platform: "macOS"
        )

        if output.json {
            try JSONPrinter.print(data)
            return
        }

        if output.quiet {
            return
        }

        print("notifyctl \(data.version)")
    }
}

private extension VersionCommand {
    func swiftVersion() -> String {
        #if swift(>=6.0)
        return "6.x"
        #elseif swift(>=5.10)
        return "5.10"
        #elseif swift(>=5.9)
        return "5.9"
        #else
        return "unknown"
        #endif
    }
}

private struct VersionData: Codable {
    let name: String
    let version: String
    let swift: String
    let platform: String
}
