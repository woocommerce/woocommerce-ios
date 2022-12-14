import AppIntents
import Yosemite
import Foundation

@available(iOS 16, *)
struct SearchEmptyOrderAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Order"
    static var openAppWhenRun = true

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentSearchOrders()

        return .result()
    }
}
