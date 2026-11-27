import Foundation
import Yosemite

/// View model for `EnableAnalyticsView`
///
@MainActor
final class EnableAnalyticsViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    private static let maximumRetries = 1

    @Published private(set) var enablingAnalyticsInProgress: Bool = false

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Enables Analytics for the current store
    /// Since toggling setting for analytics always fails at the first try with error:
    /// `This request method does not support body parameters.`,
    /// we allow retrying the request twice to avoid false failure.
    ///
    func enableAnalytics(retries: Int = 0,
                         onSuccess: @escaping @MainActor @Sendable () -> Void,
                         onFailure: @escaping @MainActor @Sendable () -> Void) {
        enablingAnalyticsInProgress = true
        let action = SettingAction.enableAnalyticsSetting(siteID: siteID) { [weak self] result in
            // SettingStore delivers success on the main storage completion queue and failures from the main network queue.
            MainActor.assumeIsolated {
                guard let self else { return }
                self.enablingAnalyticsInProgress = false
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    if retries == Self.maximumRetries {
                        DDLogError("⛔️ Error enabling analytics: \(error)")
                        onFailure()
                    } else {
                        self.enableAnalytics(retries: retries + 1, onSuccess: onSuccess, onFailure: onFailure)
                    }
                }
            }
        }
        stores.dispatch(action)
    }
}
