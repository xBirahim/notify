import ArgumentParser
import Foundation

enum CommandOutput {
    static func success<T: Codable>(
        command: String,
        id: String? = nil,
        status: String,
        data: T?,
        json: Bool,
        quiet: Bool = false
    ) throws {
        if json {
            try JSONPrinter.print(
                ResultEnvelope(
                    id: id,
                    command: command,
                    status: status,
                    data: data,
                    error: nil
                )
            )
            return
        }

        if quiet {
            return
        }
    }

    static func failure(
        command: String,
        id: String? = nil,
        error: NotifyError,
        json: Bool
    ) throws -> Never {
        if json {
            try JSONPrinter.print(
                ResultEnvelope<EmptyData>(
                    id: id,
                    command: command,
                    status: "error",
                    data: nil,
                    error: error.payload
                )
            )
        } else {
            let line = "Error (\(error.payload.code)): \(error.payload.message)"
            FileHandle.standardError.write(Data((line + "\n").utf8))
            if let detail = error.payload.detail {
                FileHandle.standardError.write(Data((detail + "\n").utf8))
            }
        }

        throw ExitCode(error.exitCode)
    }
}

struct EmptyData: Codable {}
