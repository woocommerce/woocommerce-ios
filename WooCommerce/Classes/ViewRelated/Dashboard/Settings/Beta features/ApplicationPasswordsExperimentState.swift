import Foundation
import Yosemite

final class ApplicationPasswordsExperimentState {
    private let stores: StoresManager
    private let availabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol

    init(
        stores: StoresManager = ServiceLocator.stores,
        availabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol = ApplicationPasswordsExperimentAvailabilityChecker()
    ) {
        self.stores = stores
        self.availabilityChecker = availabilityChecker
    }

    var isAvailableAndEnabled: Bool {
        get async {
            let isAvailable = await availabilityChecker.fetchAvailability()
            let isEnabled = await isEnabled
            return isAvailable && isEnabled
        }
    }

    @MainActor
    private var isEnabled: Bool {
        get async {
            return await withCheckedContinuation { continuation in
                ServiceLocator.stores.dispatch(
                    AppSettingsAction.getAppPasswordsExperimentSettingState { isOn in
                        continuation.resume(with: .success(isOn))
                    }
                )
            }
        }
    }
}

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
