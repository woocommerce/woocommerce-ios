import AppIntents
import SwiftUI
import Foundation
import WidgetKit


@available(iOS 16, *)
struct GoToPOSAppIntent: AppIntent {
    // looks up in our Localizable.string to localize
    static var title: LocalizedStringResource = "Go to POS"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDelegate.shared.tabBarController?.navigate(to: HubMenuDestination.POS)
        ServiceLocator.analytics.track(event: .AppIntents.shortcutWasOpened(with: .collectPayment))

        return .result()
    }
}

@available(iOS 16, *)
extension GoToPOSAppIntent {
    enum Localization {
        // Here to be added to Localizable.strings so it can be looked up by the `LocalizedStringResource` above
        static let title = NSLocalizedString("Go to POS", comment: "Title for the Go TO POS iOS Shortcut")

    }
}

@available(iOS 18.0, *)
struct GoToPOSControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {

        StaticControlConfiguration(
            kind: "com.automattic.woocommerce.gotoposcontrol"
        ) {
            ControlWidgetButton(action: GoToPOSAppIntent()) { // <-- HERE
                Label("Open Home", systemImage: "house")
            }
        }        
    }
}
