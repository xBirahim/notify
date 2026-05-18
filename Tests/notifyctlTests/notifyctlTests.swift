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
}

private struct EnvelopeData: Codable, Equatable {
    let message: String
}
#endif
