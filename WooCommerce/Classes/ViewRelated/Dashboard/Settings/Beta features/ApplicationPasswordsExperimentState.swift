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
        updateAvailability()
    }

    @Published private(set) var isAvailableAndEnabled: Bool = true

    @MainActor
    private var isEnabled: Bool {
        get async {
            return await withCheckedContinuation { continuation in
                stores.dispatch(
                    AppSettingsAction.getAppPasswordsExperimentSettingState { isOn in
                        continuation.resume(with: .success(isOn))
                    }
                )
            }
        }
    }

    private func updateAvailability() {
        Task { @MainActor in
            let isAvailable = await availabilityChecker.fetchAvailability()
            let isEnabled = await isEnabled
            isAvailableAndEnabled = isAvailable && isEnabled
        }
    }
}

protocol ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    var isAvailable: Bool { get }
    func fetchAvailability() async -> Bool
}

final class ApplicationPasswordsExperimentAvailabilityChecker: ApplicationPasswordsExperimentAvailabilityCheckerProtocol {
    private let userDefaults: UserDefaults
    private let stores: StoresManager

    init(userDefaults: UserDefaults = .standard, stores: StoresManager = ServiceLocator.stores) {
        self.userDefaults = userDefaults
        self.stores = stores
    }

    var isAvailable: Bool {
        /// The feature is only available when the user is signed in using WordPress.com account
        let isUserAuthenticatedByWPCom = !stores.isAuthenticatedWithoutWPCom
        return isUserAuthenticatedByWPCom && cachedRemoteFFValue
    }

    private var cachedRemoteFFValue: Bool {
        get {
            userDefaults[.applicationPasswordsExperimentRemoteFFValue] ?? false
        } set {
            userDefaults[.applicationPasswordsExperimentRemoteFFValue] = newValue
        }
    }

    func fetchAvailability() async -> Bool {
        await withCheckedContinuation { continuation in
            //TODO: - put the remote FF checking here
            //For now rely on local FF for mocked value to avoid unwanted exposure
            let mockResultValue = ServiceLocator.featureFlagService.isFeatureFlagEnabled(
                .applicationPasswordExperiment
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                continuation.resume(returning: mockResultValue)
            }

            cachedRemoteFFValue = mockResultValue
        }
    }
}
