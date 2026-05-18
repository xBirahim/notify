import Foundation

enum UserInfoParser {
    static func parse(_ pairs: [String]) throws -> [String: String] {
        var output: [String: String] = [:]
        for pair in pairs {
            guard let delimiter = pair.firstIndex(of: "=") else {
                throw NotifyCtlError.invalidInput(
                    message: "Invalid --user-info entry.",
                    detail: "Expected key=value, got '\(pair)'."
                )
            }

            let key = String(pair[..<delimiter]).trimmingCharacters(in: .whitespacesAndNewlines)
            let valueStart = pair.index(after: delimiter)
            let value = String(pair[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)

            if key.isEmpty {
                throw NotifyCtlError.invalidInput(
                    message: "Invalid --user-info entry.",
                    detail: "Key cannot be empty."
                )
            }

            output[key] = value
        }

        return output
    }
}
