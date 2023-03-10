import AppIntents
import Yosemite
import Foundation


@available(iOS 16, *)
struct CollectPaymentAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Collect Payment"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentCollectPayment()

        return .result()
    }
}
