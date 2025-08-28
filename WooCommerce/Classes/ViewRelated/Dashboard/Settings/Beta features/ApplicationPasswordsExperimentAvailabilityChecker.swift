import Foundation

protocol ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    var cachedValue: Bool { get }
    func fetchAvailability() async -> Bool
}

final class ApplicationPasswordsExperimentAvailabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    var cachedValue: Bool {
        return false
    }

    func fetchAvailability() async -> Bool {
        await withCheckedContinuation { continuation in
            //TODO: - put the remote FF checking here
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                continuation.resume(returning: true)
            }

            //TODO: - save fetched value to local cache
        }
    }
}
