import Foundation
import SwiftUI

/// Main view for the plan subscription settings.
///
final class SubscriptionsHostingController: UIHostingController<SubscriptionsView> {

    init(siteID: Int64) {
        let viewModel = SubscriptionsViewModel()
        super.init(rootView: .init(viewModel: viewModel))

        rootView.onReportIssueTapped = { [weak self] in
            self?.showContactSupportForm()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showContactSupportForm() {
        let supportController = SupportFormHostingController(viewModel: .init())
        supportController.show(from: self)
    }
}

/// Main view for the plan settings.
///
struct SubscriptionsView: View {

    /// Drives the view.
    ///
    @StateObject var viewModel: SubscriptionsViewModel

    /// Closure to be invoked when the "Report Issue" button is tapped.
    ///
    var onReportIssueTapped: (() -> ())?

    var body: some View {
        List {
            Section(content: {
                Text(Localization.currentPlan(viewModel.planName))
                    .bodyStyle()
                Button(action: {
                    viewModel.onManageSubscriptionButtonTapped()
                }, label: {
                    Text(Localization.manageSubscription)
                })
                .linkStyle()
                .renderedIf(viewModel.shouldShowManageSubscriptionButton)

            }, header: {
                Text(Localization.subscriptionStatus)
            }, footer: {
                Text(viewModel.planInfo)
            })

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
private extension SubscriptionsView {
    enum Layout {
        static let featureSpacing = 12.0
        static let sectionsSpacing = 24.0
    }
    enum Localization {
        static let title = NSLocalizedString("Subscriptions", comment: "Title for the Subscriptions / Upgrades view")
        static let subscriptionStatus = NSLocalizedString("Subscription Status", comment: "Title for the plan section on the subscriptions view. Uppercased")
        static let experienceFeatures = NSLocalizedString("Experience more of our features and services beyond the app",
                                                    comment: "Title for the features list in the Subscriptions Screen")
        static let manageSubscription = NSLocalizedString("Manage Your Subscription", comment: "Title for the button to manage subscriptions")
        static let troubleshooting = NSLocalizedString("Troubleshooting",
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
            SubscriptionsView(viewModel: .init())
        }
    }
}
