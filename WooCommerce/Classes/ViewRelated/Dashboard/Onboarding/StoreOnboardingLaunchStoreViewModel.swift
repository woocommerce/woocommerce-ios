import SwiftUI
import Yosemite

/// View model for `StoreOnboardingLaunchStoreView`.
final class StoreOnboardingLaunchStoreViewModel: ObservableObject {
    let siteURL: URL

    @Published private(set) var isLaunchingStore: Bool = false
    @Published var error: SiteLaunchError?

    private let siteID: Int64
    private let stores: StoresManager
    private let onLaunch: () -> Void

    init(siteURL: URL,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onLaunch: @escaping () -> Void) {
        self.siteURL = siteURL
        self.siteID = siteID
        self.stores = stores
        self.onLaunch = onLaunch
    }

    @MainActor
    func launchStore() async {
        error = nil
        isLaunchingStore = true
        let result = await launchStoreRemotely()
        switch result {
        case .success:
            onLaunch()
        case .failure(let error):
            self.error = error
        }
        isLaunchingStore = false
    }
}

private extension StoreOnboardingLaunchStoreViewModel {
    @MainActor
    func launchStoreRemotely() async -> Result<Void, SiteLaunchError> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.launchSite(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }
}
