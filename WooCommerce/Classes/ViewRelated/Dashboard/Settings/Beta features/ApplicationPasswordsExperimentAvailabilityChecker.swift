import Foundation

protocol ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    var cachedValue: Bool { get }
    func fetchAvailability() async -> Bool
}

final class ApplicationPasswordsExperimentAvailabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var cachedValue: Bool {
        get {
            userDefaults[.applicationPasswordsExperimentRemoteFFValue] ?? false
        } set {
            userDefaults[.applicationPasswordsExperimentRemoteFFValue] = newValue
        }
    }

    func fetchAvailability() async -> Bool {
        await withCheckedContinuation { continuation in
            //TODO: - put the remote FF checking here
            let mockResultValue = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                continuation.resume(returning: mockResultValue)
            }

            cachedValue = mockResultValue
        }
    }
}
