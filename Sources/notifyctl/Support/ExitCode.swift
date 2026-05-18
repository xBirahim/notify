import ArgumentParser

enum NotifyExitCode: Int32 {
    case success = 0
    case notFound = 44
    case usage = 64
    case invalidInput = 65
    case permissionDenied = 69
    case systemError = 70
    case timeout = 124
    case interrupted = 130
}

extension ExitCode {
    init(_ code: NotifyExitCode) {
        self.init(code.rawValue)
    }
}
