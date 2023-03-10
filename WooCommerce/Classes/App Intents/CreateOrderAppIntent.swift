import AppIntents
import Yosemite
import Foundation


@available(iOS 16, *)
struct CreateOrderAppIntent: AppIntent {
    // looks up in our Localizable.string to localize
    static var title: LocalizedStringResource = "Create order"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentOrderCreationFlow()
        ServiceLocator.analytics.track(event: WooAnalyticsEvent.AppIntents.shortcutWasOpened(with: .createOrder))

        return .result()
    }
}

@available(iOS 16, *)
extension CreateOrderAppIntent {
    enum Localization {
        // Here to be added to Localizable.strings so it can be looked up by the `LocalizedStringResource` above
        static let title = NSLocalizedString("Create order", comment: "Title for the Create Order iOS Shortcut")

    }
}
