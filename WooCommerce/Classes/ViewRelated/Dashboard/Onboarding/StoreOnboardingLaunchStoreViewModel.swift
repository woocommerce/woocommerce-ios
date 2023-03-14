import SwiftUI
import Yosemite

final class StoreOnboardingLaunchStoreViewModel: ObservableObject {
    let siteURL: URL

    @Published private(set) var isLaunchingStore: Bool = false

    init(siteURL: URL) {
        self.siteURL = siteURL
    }

    func launchStore() async throws {
        isLaunchingStore = true
        #warning("TODO: 9122 - launch store action")
        throw StoreCreationError.invalidCompletionPath
        isLaunchingStore = false
    }
}
