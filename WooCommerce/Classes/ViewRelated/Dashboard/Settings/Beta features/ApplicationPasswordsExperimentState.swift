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
                stores.dispatch(
                    AppSettingsAction.getAppPasswordsExperimentSettingState { isOn in
                        continuation.resume(with: .success(isOn))
                    }
                )
            }
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

    @MainActor
    func fetchAvailability() async -> Bool {
        let isEnabled = await withCheckedContinuation { continuation in
            stores.dispatch(FeatureFlagAction.isRemoteFeatureFlagEnabled(
                .appPasswordsForJetpackSites,
                defaultValue: false
            ) { isEnabled in
                continuation.resume(returning: isEnabled)
            })
        }
        cachedRemoteFFValue = isEnabled
        return isEnabled
    }
}
