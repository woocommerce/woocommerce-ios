import Foundation
import SwiftUI

/// Main view for the plan settings.
///
final class UpgradesHostingController: UIHostingController<UpgradesView> {

    init(currentPlan: String, planInfo: String) {
        super.init(rootView: .init(currentPlan: currentPlan, planInfo: planInfo))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Main view for the plan settings.
///
struct UpgradesView: View {

    /// Store's Current Plan name
    let currentPlan: String

    /// Store's plan information
    let planInfo: String

    var body: some View {
        List {
            Section(content: {
                Text(Localization.currentPlan(currentPlan))
                    .bodyStyle()

                Button(Localization.upgradeNow) {
                    print("Upgrade Now tapped")
                }
                .linkStyle()
            }, header: {
                Text(Localization.subscriptionStatus)
            }, footer: {
                Text(planInfo)
            })

            Button(Localization.cancelTrial) {
                print("Cancel Free Trial tapped")
            }
            .foregroundColor(Color(.systemRed))

            Section(Localization.troubleshooting) {
                Button(Localization.report) {
                    print("Report Subscription Tapped")
                }
                .linkStyle()
            }
        }
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Definitions
private extension UpgradesView {
    enum Localization {
        static let title = NSLocalizedString("Subscriptions", comment: "Title for the Subscriptions / Upgrades view")
        static let subscriptionStatus = NSLocalizedString("SUBSCRIPTION STATUS", comment: "Title for the plan section on the subscriptions view. Uppercased")
        static let upgradeNow = NSLocalizedString("Upgrade Now", comment: "Title for the button to upgrade from a free trial")
        static let cancelTrial = NSLocalizedString("Cancel Free Trial", comment: "Title for the button to cancel a free trial")
        static let troubleshooting = NSLocalizedString("TROUBLESHOOTING",
                                                       comment: "Title for the section to contact support on the subscriptions view. Uppercased")
        static let report = NSLocalizedString("Report Subscription Issue", comment: "Title for the button to contact support on the Subscriptions view")

        static func currentPlan(_ plan: String) -> String {
            let format = NSLocalizedString("Current: %@", comment: "Reads like: Current: Free Trial")
            return .localizedStringWithFormat(format, plan)
        }
    }
}

// MARK: Previews
struct UpgradesPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UpgradesView(currentPlan: "Free Trial",
                         planInfo: "You are in the 14-day free trial. The free trial will end in 6 days. " +
                                   "Upgrade to unlock new features and keep your store running.")
        }
    }
}
