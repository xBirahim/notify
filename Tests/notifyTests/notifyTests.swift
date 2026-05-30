#if canImport(XCTest)
import Foundation
import XCTest
@testable import notify

// MARK: - UserInfoParser

final class UserInfoParserTests: XCTestCase {
    func testParseValidPairs() throws {
        let parsed = try UserInfoParser.parse(["env=prod", "build = 42", "empty="])
        XCTAssertEqual(parsed["env"], "prod")
        XCTAssertEqual(parsed["build"], "42")
        XCTAssertEqual(parsed["empty"], "")
    }

    func testRejectsInvalidPairs() {
        XCTAssertThrowsError(try UserInfoParser.parse(["missing-delimiter"])) { error in
            guard case NotifyError.invalidInput = error else {
                XCTFail("Expected invalidInput, got \(error)"); return
            }
        }
    }

    func testRejectsEmptyKey() {
        XCTAssertThrowsError(try UserInfoParser.parse(["=value"])) { error in
            guard case NotifyError.invalidInput = error else {
                XCTFail("Expected invalidInput, got \(error)"); return
            }
        }
    }

    func testEmptyInputReturnsEmptyDict() throws {
        let parsed = try UserInfoParser.parse([])
        XCTAssertTrue(parsed.isEmpty)
    }

    func testValueWithMultipleEquals() throws {
        let parsed = try UserInfoParser.parse(["url=https://example.com?a=1&b=2"])
        XCTAssertEqual(parsed["url"], "https://example.com?a=1&b=2")
    }

    func testTrimsWhitespaceFromKeyAndValue() throws {
        let parsed = try UserInfoParser.parse(["  env  =  prod  "])
        XCTAssertEqual(parsed["env"], "prod")
    }
}

// MARK: - NotifyError

final class NotifyErrorTests: XCTestCase {
    func testPermissionDeniedMapsToExitCodeAndPayload() {
        let error = NotifyError.permissionDenied(
            message: "Notifications are denied.",
            detail: "Enable notifications in macOS Settings."
        )
        XCTAssertEqual(error.exitCode, .permissionDenied)
        XCTAssertEqual(error.payload.code, "permission_denied")
        XCTAssertEqual(error.payload.message, "Notifications are denied.")
        XCTAssertEqual(error.payload.detail, "Enable notifications in macOS Settings.")
    }

    func testAllCasesMapToCorrectExitCodes() {
        XCTAssertEqual(NotifyError.invalidInput(message: "").exitCode, .invalidInput)
        XCTAssertEqual(NotifyError.permissionDenied(message: "").exitCode, .permissionDenied)
        XCTAssertEqual(NotifyError.notFound(message: "").exitCode, .notFound)
        XCTAssertEqual(NotifyError.systemError(message: "").exitCode, .systemError)
    }

    func testAllCasesMapToCorrectPayloadCodes() {
        XCTAssertEqual(NotifyError.invalidInput(message: "").payload.code, "invalid_input")
        XCTAssertEqual(NotifyError.permissionDenied(message: "").payload.code, "permission_denied")
        XCTAssertEqual(NotifyError.notFound(message: "").payload.code, "not_found")
        XCTAssertEqual(NotifyError.systemError(message: "").payload.code, "system_error")
    }

    func testPayloadWithNoDetailIsNil() {
        let error = NotifyError.notFound(message: "Notification not found.")
        XCTAssertNil(error.payload.detail)
    }
}

// MARK: - NotifyExitCode

final class NotifyExitCodeTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(NotifyExitCode.success.rawValue, 0)
        XCTAssertEqual(NotifyExitCode.notFound.rawValue, 44)
        XCTAssertEqual(NotifyExitCode.usage.rawValue, 64)
        XCTAssertEqual(NotifyExitCode.invalidInput.rawValue, 65)
        XCTAssertEqual(NotifyExitCode.permissionDenied.rawValue, 69)
        XCTAssertEqual(NotifyExitCode.systemError.rawValue, 70)
        XCTAssertEqual(NotifyExitCode.timeout.rawValue, 124)
        XCTAssertEqual(NotifyExitCode.interrupted.rawValue, 130)
    }
}

// MARK: - ResultEnvelope

final class ResultEnvelopeTests: XCTestCase {
    func testRoundTripWithData() throws {
        let envelope = ResultEnvelope(
            id: "build-123",
            command: "send",
            status: "delivered",
            data: EnvelopeData(message: "ok"),
            error: nil
        )
        let encoded = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(ResultEnvelope<EnvelopeData>.self, from: encoded)

        XCTAssertEqual(decoded.id, "build-123")
        XCTAssertEqual(decoded.command, "send")
        XCTAssertEqual(decoded.status, "delivered")
        XCTAssertEqual(decoded.data?.message, "ok")
        XCTAssertNil(decoded.error)
    }

    func testRoundTripWithError() throws {
        let payload = ErrorPayload(code: "not_found", message: "Not found.", detail: nil)
        let envelope = ResultEnvelope<EnvelopeData>(
            id: nil,
            command: "get",
            status: "error",
            data: nil,
            error: payload
        )
        let encoded = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(ResultEnvelope<EnvelopeData>.self, from: encoded)

        XCTAssertNil(decoded.id)
        XCTAssertEqual(decoded.status, "error")
        XCTAssertNil(decoded.data)
        XCTAssertEqual(decoded.error?.code, "not_found")
        XCTAssertEqual(decoded.error?.message, "Not found.")
    }

    func testNilIdEncodesAndDecodesCorrectly() throws {
        let envelope = ResultEnvelope<EnvelopeData>(
            id: nil, command: "list", status: "ok", data: nil, error: nil
        )
        let encoded = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(ResultEnvelope<EnvelopeData>.self, from: encoded)
        XCTAssertNil(decoded.id)
    }
}

// MARK: - NotificationRecord

final class NotificationRecordTests: XCTestCase {
    func testSnakeCaseCodingKeys() throws {
        let json = """
        {"id":"abc","title":"T","subtitle":"S","body":"B",\
        "created_at":"2026-01-01","updated_at":"2026-01-02"}
        """
        let record = try JSONDecoder().decode(NotificationRecord.self, from: Data(json.utf8))
        XCTAssertEqual(record.id, "abc")
        XCTAssertEqual(record.createdAt, "2026-01-01")
        XCTAssertEqual(record.updatedAt, "2026-01-02")
    }

    func testRoundTripEncoding() throws {
        let record = NotificationRecord(
            id: "r1", title: "Hi", subtitle: "Sub", body: "Body",
            category: "job", thread: "t1", url: "https://example.com",
            createdAt: "2026-05-01", updatedAt: nil
        )
        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(NotificationRecord.self, from: data)
        XCTAssertEqual(decoded.id, "r1")
        XCTAssertEqual(decoded.category, "job")
        XCTAssertEqual(decoded.thread, "t1")
        XCTAssertNil(decoded.updatedAt)
    }
}

// MARK: - NotifyCategory & NotificationSound

final class NotifyCategoryTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(NotifyCategory.plain.rawValue, "plain")
        XCTAssertEqual(NotifyCategory.alert.rawValue, "alert")
        XCTAssertEqual(NotifyCategory.job.rawValue, "job")
        XCTAssertEqual(NotifyCategory.deploy.rawValue, "deploy")
    }

    func testArgumentParsingAcceptsValidValues() {
        XCTAssertNotNil(NotifyCategory(argument: "plain"))
        XCTAssertNotNil(NotifyCategory(argument: "alert"))
        XCTAssertNotNil(NotifyCategory(argument: "job"))
        XCTAssertNotNil(NotifyCategory(argument: "deploy"))
    }

    func testArgumentParsingRejectsUnknownValues() {
        XCTAssertNil(NotifyCategory(argument: "unknown"))
        XCTAssertNil(NotifyCategory(argument: "PLAIN"))
    }

    func testNotificationSoundRawValues() {
        XCTAssertEqual(NotificationSound.default.rawValue, "default")
        XCTAssertEqual(NotificationSound.none.rawValue, "none")
        XCTAssertEqual(NotificationSound.named("Purr").rawValue, "Purr")
    }

    func testNotificationSoundArgumentParsing() {
        XCTAssertEqual(NotificationSound(argument: "default"), .default)
        XCTAssertEqual(NotificationSound(argument: "none"), NotificationSound.none)
        XCTAssertEqual(NotificationSound(argument: "Purr"), .named("Purr"))
        XCTAssertEqual(NotificationSound(argument: "Sosumi"), .named("Sosumi"))
    }

    func testNotificationSoundCodable() throws {
        let cases: [NotificationSound] = [.default, .none, .named("Purr"), .named("Sosumi")]
        for sound in cases {
            let data = try JSONEncoder().encode(sound)
            let decoded = try JSONDecoder().decode(NotificationSound.self, from: data)
            XCTAssertEqual(decoded, sound)
        }
    }
}

// MARK: - LocalStore

final class LocalStoreTests: XCTestCase {
    func testFallbackPathWhenApplicationSupportUnavailable() {
        let home = URL(fileURLWithPath: "/tmp/notify-tests-\(NSUUID().uuidString)", isDirectory: true)
        let fm = FallbackFileManager(home: home)
        let store = LocalStore(fileManager: fm)

        XCTAssertEqual(
            store.notificationsURL.path,
            home.appendingPathComponent(".local/share/notify/notifications.jsonl").path
        )
        XCTAssertEqual(
            store.actionsURL.path,
            home.appendingPathComponent(".local/share/notify/actions.jsonl").path
        )
        XCTAssertEqual(
            fm.createdDirectory?.path,
            home.appendingPathComponent(".local/share/notify").path
        )
    }

    func testAppendAndRetrieveNotification() throws {
        let fm = TempAppSupportFileManager()
        defer { fm.cleanup() }

        let store = LocalStore(fileManager: fm)
        let record = NotificationRecord(
            id: "n1", title: "Build done", subtitle: "", body: "Success",
            category: nil, thread: nil, url: nil, createdAt: "2026-05-01", updatedAt: nil
        )
        try store.appendNotification(record)

        let retrieved = store.getNotification(id: "n1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.body, "Success")
        XCTAssertEqual(retrieved?.title, "Build done")
    }

    func testGetReturnsNilForUnknownId() throws {
        let fm = TempAppSupportFileManager()
        defer { fm.cleanup() }

        let store = LocalStore(fileManager: fm)
        XCTAssertNil(store.getNotification(id: "does-not-exist"))
    }

    func testListDeduplicatesById() throws {
        let fm = TempAppSupportFileManager()
        defer { fm.cleanup() }

        let store = LocalStore(fileManager: fm)
        let v1 = NotificationRecord(
            id: "dup", title: "v1", subtitle: "", body: "first",
            category: nil, thread: nil, url: nil, createdAt: "2026-05-01", updatedAt: nil
        )
        let v2 = NotificationRecord(
            id: "dup", title: "v2", subtitle: "", body: "second",
            category: nil, thread: nil, url: nil, createdAt: "2026-05-02", updatedAt: nil
        )
        try store.appendNotification(v1)
        try store.appendNotification(v2)

        let all = store.listNotifications()
        let matching = all.filter { $0.id == "dup" }
        XCTAssertEqual(matching.count, 1)
        XCTAssertEqual(matching.first?.body, "second")
    }

    func testListFiltersByThread() throws {
        let fm = TempAppSupportFileManager()
        defer { fm.cleanup() }

        let store = LocalStore(fileManager: fm)
        let r1 = NotificationRecord(
            id: "a", title: "", subtitle: "", body: "A",
            category: nil, thread: "ci", url: nil, createdAt: nil, updatedAt: nil
        )
        let r2 = NotificationRecord(
            id: "b", title: "", subtitle: "", body: "B",
            category: nil, thread: "deploy", url: nil, createdAt: nil, updatedAt: nil
        )
        try store.appendNotification(r1)
        try store.appendNotification(r2)

        let ci = store.listNotifications(thread: "ci")
        XCTAssertEqual(ci.count, 1)
        XCTAssertEqual(ci.first?.id, "a")
    }

    func testFindIdsByThread() throws {
        let fm = TempAppSupportFileManager()
        defer { fm.cleanup() }

        let store = LocalStore(fileManager: fm)
        for i in 1...3 {
            let r = NotificationRecord(
                id: "t\(i)", title: "", subtitle: "", body: "body",
                category: nil, thread: "batch", url: nil, createdAt: nil, updatedAt: nil
            )
            try store.appendNotification(r)
        }
        let other = NotificationRecord(
            id: "other", title: "", subtitle: "", body: "other",
            category: nil, thread: "unrelated", url: nil, createdAt: nil, updatedAt: nil
        )
        try store.appendNotification(other)

        let ids = store.findIdsByThread("batch")
        XCTAssertEqual(Set(ids), Set(["t1", "t2", "t3"]))
    }
}

// MARK: - Helpers

private struct EnvelopeData: Codable, Equatable {
    let message: String
}

private final class FallbackFileManager: FileManager, @unchecked Sendable {
    private let home: URL
    var createdDirectory: URL?

    init(home: URL) {
        self.home = home
        super.init()
    }

    override var homeDirectoryForCurrentUser: URL { home }

    override func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        if directory == .applicationSupportDirectory && domainMask == .userDomainMask {
            return []
        }
        return super.urls(for: directory, in: domainMask)
    }

    override func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        createdDirectory = url
    }
}

private final class TempAppSupportFileManager: FileManager, @unchecked Sendable {
    let tempDir: URL

    override init() {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("notify-tests-\(NSUUID().uuidString)")
        super.init()
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        if directory == .applicationSupportDirectory && domainMask == .userDomainMask {
            return [tempDir]
        }
        return super.urls(for: directory, in: domainMask)
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: tempDir)
    }
}
#endif
