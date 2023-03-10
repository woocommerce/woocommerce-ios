import AppIntents
import Yosemite
import Foundation


@available(iOS 16, *)
struct CollectPaymentAppIntent: AppIntent {
    // looks up in our Localizable.string to localize
    static var title: LocalizedStringResource = "Collect payment"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentCollectPayment()
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.AppIntents.shortcutWasOpened(with: .collectPayment))

        return .result()
    }
}

@available(iOS 16, *)
extension CollectPaymentAppIntent {
    enum Localization {
        // Here to be added to Localizable.strings so it can be looked up by `theLocalizedStringResource` above
        static let title = NSLocalizedString("Collect payment", comment: "Title for the Collect Payment iOS Shortcut")

    }
}
