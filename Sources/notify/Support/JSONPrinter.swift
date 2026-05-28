import Foundation

enum JSONPrinter {
    static func print<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        if let string = String(data: data, encoding: .utf8) {
            Swift.print(string)
        }
    }
}
