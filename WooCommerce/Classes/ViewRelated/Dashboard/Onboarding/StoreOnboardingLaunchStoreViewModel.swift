import SwiftUI
import Yosemite

/// View model for `StoreOnboardingLaunchStoreView`.
final class StoreOnboardingLaunchStoreViewModel: ObservableObject {
    let siteURL: URL

    @Published private(set) var isLaunchingStore: Bool = false

    init(siteURL: URL) {
        self.siteURL = siteURL
    }

    @MainActor
    func launchStore() async throws {
        isLaunchingStore = true
        #warning("TODO: 9122 - launch store action")
    }
}
