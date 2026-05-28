import Foundation

enum NotifyError: Error {
    case invalidInput(message: String, detail: String? = nil)
    case permissionDenied(message: String, detail: String? = nil)
    case notFound(message: String, detail: String? = nil)
    case systemError(message: String, detail: String? = nil)
}

extension NotifyError {
    var exitCode: NotifyExitCode {
        switch self {
        case .invalidInput:
            return .invalidInput
        case .permissionDenied:
            return .permissionDenied
        case .notFound:
            return .notFound
        case .systemError:
            return .systemError
        }
    }

    var payload: ErrorPayload {
        switch self {
        case let .invalidInput(message, detail):
            return ErrorPayload(code: "invalid_input", message: message, detail: detail)
        case let .permissionDenied(message, detail):
            return ErrorPayload(code: "permission_denied", message: message, detail: detail)
        case let .notFound(message, detail):
            return ErrorPayload(code: "not_found", message: message, detail: detail)
        case let .systemError(message, detail):
            return ErrorPayload(code: "system_error", message: message, detail: detail)
        }
    }
}
