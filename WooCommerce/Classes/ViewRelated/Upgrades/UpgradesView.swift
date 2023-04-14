import Foundation
import SwiftUI

/// Main view for the plan settings.
///
final class UpgradesHostingController: UIHostingController<UpgradesView> {

    init(siteID: Int64) {
        let viewModel = UpgradesViewModel(siteID: siteID)
        super.init(rootView: .init(viewModel: viewModel))

        // Assign after of `init` for `self` to be properly initialized.
        rootView.onUpgradeNowTapped = { [weak self] in
            self?.showUpgradePlanWebView(siteID: siteID, viewModel: viewModel)
        }

        rootView.onReportIssueTapped = { [weak self] in
            self?.showContactSupportForm()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows a web view for the merchant to update their site plan.
    ///
    private func showUpgradePlanWebView(siteID: Int64, viewModel: UpgradesViewModel) {
        let upgradeController = UpgradePlanCoordinatingController(siteID: siteID, source: .upgradesScreen, onSuccess: {
            viewModel.loadPlan()
        })
        present(upgradeController, animated: true)
    }

    private func showContactSupportForm() {
        let supportController = SupportFormHostingController(viewModel: .init())
        supportController.show(from: self)
    }
}

/// Main view for the plan settings.
///
struct UpgradesView: View {

    /// Drives the view.
    ///
    @StateObject var viewModel: UpgradesViewModel

    /// Closure to be invoked when the "Upgrade Now" button is tapped.
    ///
    var onUpgradeNowTapped: (() -> ())?

    /// Closure to be invoked when the "Report Issue" button is tapped.
    ///
    var onReportIssueTapped: (() -> ())?

    var body: some View {
        List {
            Section(content: {
                Text(Localization.currentPlan(viewModel.planName))
                    .bodyStyle()

                Button(Localization.upgradeNow) {
                    onUpgradeNowTapped?()
                }
                .linkStyle()
                .renderedIf(viewModel.shouldShowUpgradeButton)

            }, header: {
                Text(Localization.subscriptionStatus)
            }, footer: {
                Text(viewModel.planInfo)
            })

            Button(Localization.cancelTrial) {
                print("Cancel Free Trial tapped")
            }
            .foregroundColor(Color(.systemRed))
            .renderedIf(viewModel.shouldShowCancelTrialButton)

            Section(Localization.troubleshooting) {
                Button(Localization.report) {
                    onReportIssueTapped?()
                }
                .linkStyle()
            }
        }
        .notice($viewModel.errorNotice, autoDismiss: false)
        .redacted(reason: viewModel.showLoadingIndicator ? .placeholder : [])
        .shimmering(active: viewModel.showLoadingIndicator)
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadPlan()
        }
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
            UpgradesView(viewModel: .init(siteID: 0))
        }
    }
}
