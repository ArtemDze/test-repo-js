import Foundation

enum FootlightDeadlineError: Error {
    case expired
}

enum FootlightLinkProbe {

    private static let footlight_offlineCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorTimedOut,
        NSURLErrorDNSLookupFailed,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorDataNotAllowed,
        NSURLErrorInternationalRoamingOff,
    ]

    static func footlight_looksLikeTransportFailure(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain, footlight_offlineCodes.contains(ns.code) {
            return true
        }
        if error is FootlightDeadlineError {
            return true
        }
        if let nested = ns.userInfo[NSUnderlyingErrorKey] as? NSError,
           nested.domain == NSURLErrorDomain,
           footlight_offlineCodes.contains(nested.code) {
            return true
        }
        return false
    }

    static func footlight_withDeadline<T: Sendable>(
        seconds: TimeInterval,
        work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await work()
            }
            group.addTask {
                let nanos = UInt64(seconds * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanos)
                throw FootlightDeadlineError.expired
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw FootlightDeadlineError.expired
            }
            return first
        }
    }
}
