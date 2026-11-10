import Foundation
import enum Alamofire.AFError

struct ApplicationPasswordCreationCooldown {
    private var lastFailure: (error: Error, failedAt: ContinuousClock.Instant, pause: Duration)?

    func pausedFailure(at now: ContinuousClock.Instant) -> Error? {
        guard let lastFailure, now < lastFailure.failedAt + lastFailure.pause else {
            return nil
        }
        return lastFailure.error
    }

    mutating func recordFailure(_ error: Error, at now: ContinuousClock.Instant) {
        let pause: Duration = if let lastFailure, !error.isConnectionFailure {
            min(lastFailure.pause * 2, .seconds(60 * 60))
        } else {
            .seconds(10)
        }
        lastFailure = (error, now, pause)
    }

    mutating func reset() {
        lastFailure = nil
    }
}

private extension Error {
    var isConnectionFailure: Bool {
        if case .sessionTaskFailed(let underlyingError) = self as? AFError {
            return underlyingError.isConnectionFailure
        }
        let error = self as NSError
        // DNS failures and refused connections get the growing pause, so a store whose domain is gone isn't retried every 10 seconds.
        let shortPauseCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut]
        return error.domain == NSURLErrorDomain
            && shortPauseCodes.contains(error.code)
    }
}
