import AppIntents
import Yosemite
import Foundation


@available(iOS 16, *)
struct CollectPaymentAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Collect Payment"
    static var openAppWhenRun = true

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentCollectPayment()

        return .result()
    }
}
