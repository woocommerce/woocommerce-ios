import AppIntents
import Foundation


@available(iOS 16, *)
struct CollectPaymentAppIntent: AppIntent {
    // looks up in our Localizable.string to localize
    static var title: LocalizedStringResource = "Collect payment"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDelegate.shared.tabBarController?.navigate(to: OrdersDestination.createOrder)
        ServiceLocator.analytics.track(event: .AppIntents.shortcutWasOpened(with: .collectPayment))

        return .result()
    }
}

@available(iOS 16, *)
extension CollectPaymentAppIntent {
    enum Localization {
        // Here to be added to Localizable.strings so it can be looked up by the `LocalizedStringResource` above
        static let title = NSLocalizedString("Collect payment", comment: "This text appears as a title in iOS Shortcuts integration and as an alert title when initiating the payment collection flow for orders, either with or without a customer name.")

    }
}
