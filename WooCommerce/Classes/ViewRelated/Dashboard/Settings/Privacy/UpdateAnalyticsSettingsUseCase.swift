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

    init(stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.analytics = analytics
    }

    /// Async function that updates analytics choices.
    /// For WPCOM stores: Updates remotely and locally. - The local update only happens after a successful remote update.
    /// For NON-WPCOM stores: Updates locally.
    ///
    func update(optOut: Bool) async throws {
        // If we can't find an account(non-jp sites), lets commit the change immediately.
        guard let defaultAccount = stores.sessionManager.defaultAccount else {
            return analytics.setUserHasOptedOut(optOut)
        }

        let userID = defaultAccount.userID
        try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.updateAccountSettings(userID: userID, tracksOptOut: optOut) { [weak self] result in
                switch result {
                case .success:
                    self?.analytics.setUserHasOptedOut(optOut)
                    continuation.resume()
                case .failure(let error):
                    DDLogError("⛔️ Error saving the privacy choices: \(error)")
                    continuation.resume(with: .failure(error))
                    // TODO: Migrate - self?.collectInfo = !newValue // Revert to the previous value to keep the UI consistent.
                    // TODO: Migrate - self?.presentErrorUpdatingAccountSettingsNotice(optInValue: newValue)
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}
