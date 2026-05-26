#if canImport(XCTest)
import Foundation
import XCTest
@testable import notifyctl

final class NotifyCtlTests: XCTestCase {
    func testUserInfoParserParsesPairs() throws {
        let parsed = try UserInfoParser.parse(["env=prod", "build = 42", "empty="])
        XCTAssertEqual(parsed["env"], "prod")
        XCTAssertEqual(parsed["build"], "42")
        XCTAssertEqual(parsed["empty"], "")
    }

    func testUserInfoParserRejectsInvalidPairs() {
        XCTAssertThrowsError(try UserInfoParser.parse(["missing-delimiter"])) { error in
            guard case NotifyCtlError.invalidInput = error else {
                XCTFail("Expected invalidInput error, got \(error)")
                return
            }
        }
    }

    func testUserInfoParserRejectsEmptyKey() {
        XCTAssertThrowsError(try UserInfoParser.parse(["=value"])) { error in
            guard case NotifyCtlError.invalidInput = error else {
                XCTFail("Expected invalidInput error, got \(error)")
                return
            }
        }
    }

    func testResultEnvelopeRoundTrip() throws {
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

    func testNotifyCtlErrorMapsExitCodeAndPayload() {
        let error = NotifyCtlError.permissionDenied(
            message: "Notifications are denied.",
            detail: "Enable notifications in macOS Settings."
        )

        XCTAssertEqual(error.exitCode, .permissionDenied)
        XCTAssertEqual(error.payload.code, "permission_denied")
        XCTAssertEqual(error.payload.message, "Notifications are denied.")
    }

    func testLocalStoreFallsBackWhenApplicationSupportUnavailable() {
        let home = URL(fileURLWithPath: "/tmp/notifyctl-tests-\(UUID().uuidString)", isDirectory: true)
        let fileManager = FallbackFileManager(home: home)

        let store = LocalStore(fileManager: fileManager)

        XCTAssertEqual(
            store.notificationsURL.path,
            home.appendingPathComponent(".local/share/notifyctl/notifications.jsonl").path
        )
        XCTAssertEqual(
            store.actionsURL.path,
            home.appendingPathComponent(".local/share/notifyctl/actions.jsonl").path
        )
        XCTAssertEqual(
            fileManager.createdDirectory?.path,
            home.appendingPathComponent(".local/share/notifyctl").path
        )
    }
}

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

    override var homeDirectoryForCurrentUser: URL {
        home
    }

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
#endif
