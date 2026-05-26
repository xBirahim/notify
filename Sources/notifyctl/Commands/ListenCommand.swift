import ArgumentParser
import Dispatch
import Foundation
@preconcurrency import UserNotifications

struct ListenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listen",
        abstract: "Listen for notification actions (long-running process)."
    )

    @MainActor
    mutating func run() async throws {
        let service = try NotificationService.makeDefault()
        service.registerCategories()

        let center = UNUserNotificationCenter.current()
        let listener = NotificationListener()
        center.delegate = listener

        let signalWaiter = SignalWaiter(signals: [SIGINT, SIGTERM])
        await signalWaiter.wait()
    }
}

@MainActor
private final class SignalWaiter {
    private var continuation: CheckedContinuation<Void, Never>?
    private var signalSources: [DispatchSourceSignal] = []
    private var pendingSignal = false

    init(signals: [Int32]) {
        for signalNumber in signals {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { [weak self] in
                self?.resumeAndStop()
            }
            source.resume()
            signalSources.append(source)
        }
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            if pendingSignal {
                pendingSignal = false
                continuation.resume()
                return
            }
            self.continuation = continuation
        }
    }

    private func resumeAndStop() {
        for source in signalSources {
            source.cancel()
        }
        signalSources.removeAll()

        guard let continuation else {
            pendingSignal = true
            return
        }
        self.continuation = nil
        continuation.resume()
    }
}
