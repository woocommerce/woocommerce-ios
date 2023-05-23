import Foundation
import Yosemite

/// Use case in charge of updating(remotely and locally) analytics choices.
///
final class UpdateAnalyticsSettingUseCase {

    /// Stores dependency
    ///
    private let stores: StoresManager

    /// Analytics manager
    ///
    private let analytics: Analytics

    /// Defaults database
    ///
    private let userDefaults: UserDefaults

    init(stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics, userDefaults: UserDefaults = .standard) {
        self.stores = stores
        self.analytics = analytics
        self.userDefaults = userDefaults
    }

    /// Async function that updates analytics choices.
    /// For WPCOM stores: Updates remotely and locally. - The local update only happens after a successful remote update.
    /// For NON-WPCOM stores: Updates locally.
    ///
    func update(optOut: Bool) async throws {
        // There is no need to perform any request if the user hasn't changed the current analytic setting.
        guard analytics.userHasOptedIn == optOut else {
            return updateLocally(optOut: optOut)
        }

        // If we can't find an account(non-jp sites), lets commit the change immediately.
        guard let defaultAccount = stores.sessionManager.defaultAccount else {
            return updateLocally(optOut: optOut)
        }

        let userID = defaultAccount.userID
        try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.updateAccountSettings(userID: userID, tracksOptOut: optOut) { [weak self] result in
                switch result {
                case .success:
                    self?.updateLocally(optOut: optOut)
                    continuation.resume()
                case .failure(let error):
                    DDLogError("⛔️ Error saving the privacy choices: \(error)")
                    continuation.resume(with: .failure(error))
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    /// Updates the local analytics setting
    ///
    private func updateLocally(optOut: Bool) {
        analytics.setUserHasOptedOut(optOut)
        userDefaults[.hasSavedPrivacyBannerSettings] = true
    }
}
