import Foundation
import Yosemite

/// Use case in charge of updating(remotely and locally) the crash reporting choice.
///
final class UpdateCrashReportingSettingUseCase {

    /// Stores dependency
    ///
    private let stores: StoresManager

    /// Defaults database
    ///
    private let userDefaults: UserDefaults

    init(stores: StoresManager = ServiceLocator.stores, userDefaults: UserDefaults = .standard) {
        self.stores = stores
        self.userDefaults = userDefaults
    }

    /// Async function that updates the crash reporting choice.
    /// For WPCOM stores: Updates remotely and locally. - The local update only happens after a successful remote update.
    /// For NON-WPCOM stores: Updates locally.
    ///
    @MainActor func update(optOut: Bool) async throws {
        // There is no need to perform any request if the user hasn't changed the current crash reporting setting.
        guard CrashLoggingSettings.didOptIn(in: userDefaults) == optOut else {
            return
        }

        // If we can't find an account(non-jp sites), lets commit the change immediately.
        guard let defaultAccount = stores.sessionManager.defaultAccount else {
            return CrashLoggingSettings.setDidOptIn(!optOut, in: userDefaults)
        }

        let userID = defaultAccount.userID
        try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.updateCrashReportingOptOut(userID: userID, optOut: optOut) { [weak self] result in
                switch result {
                case .success:
                    if let self {
                        CrashLoggingSettings.setDidOptIn(!optOut, in: self.userDefaults)
                    }
                    continuation.resume()
                case .failure(let error):
                    DDLogError("⛔️ Error saving the crash reporting choice: \(error)")
                    continuation.resume(with: .failure(error))
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    /// Handles the remote crash reporting value received on account-settings sync.
    /// - A recorded choice (`true`/`false`) wins over the local value and is applied locally.
    /// - `nil` means no choice has been recorded on the account yet: the local value stays the source
    ///   of truth and is backfilled to the account so it persists across devices and reinstalls.
    ///
    @MainActor func handleRemoteValue(_ remoteOptOut: Bool?, userID: Int64) {
        guard let remoteOptOut else {
            return backfillRemoteValue(userID: userID)
        }

        CrashLoggingSettings.setDidOptIn(!remoteOptOut, in: userDefaults)
    }

    /// Populates the account setting from the local value. Fire-and-forget: on failure the account
    /// stays unset and the backfill is retried on the next account-settings sync.
    ///
    @MainActor private func backfillRemoteValue(userID: Int64) {
        let optOut = !CrashLoggingSettings.didOptIn(in: userDefaults)
        let action = AccountAction.updateCrashReportingOptOut(userID: userID, optOut: optOut) { result in
            if case .failure(let error) = result {
                DDLogError("⛔️ Error backfilling the crash reporting choice: \(error)")
            }
        }
        stores.dispatch(action)
    }
}
