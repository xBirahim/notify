import Foundation

struct LocalStore {
    let notificationsURL: URL
    let actionsURL: URL

    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        return enc
    }()

    init(fileManager: FileManager = .default) {
        let support: URL
        if let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            support = appSupport.appendingPathComponent("notify", isDirectory: true)
        } else {
            support = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".local/share/notify", isDirectory: true)
        }

        try? fileManager.createDirectory(at: support, withIntermediateDirectories: true)
        notificationsURL = support.appendingPathComponent("notifications.jsonl")
        actionsURL = support.appendingPathComponent("actions.jsonl")
    }

    func appendNotification(_ record: NotificationRecord) throws {
        try appendLine(record, to: notificationsURL)
    }

    func appendAction(_ event: ActionEvent) throws {
        try appendLine(event, to: actionsURL)
    }

    func getNotification(id: String) -> NotificationRecord? {
        readNotifications().reversed().first { $0.id == id }
    }

    func listNotifications(thread: String? = nil) -> [NotificationRecord] {
        var recordsById: [String: NotificationRecord] = [:]
        for record in readNotifications() {
            recordsById[record.id] = record
        }
        var result = Array(recordsById.values)
        if let thread {
            result = result.filter { $0.thread == thread }
        }
        return result.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
    }

    func findIdsByThread(_ thread: String) -> [String] {
        listNotifications(thread: thread).map(\.id)
    }
}

private extension LocalStore {
    func appendLine<T: Encodable>(_ value: T, to url: URL) throws {
        var data = try encoder.encode(value)
        data.append(0x0A)
        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } else {
            try data.write(to: url)
        }
    }

    func readNotifications() -> [NotificationRecord] {
        guard let data = try? Data(contentsOf: notificationsURL) else { return [] }
        return data
            .split(separator: 0x0A, omittingEmptySubsequences: true)
            .compactMap { line in try? decoder.decode(NotificationRecord.self, from: line) }
    }
}
