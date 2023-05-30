import Foundation
import SwiftUI
import struct Yosemite.StoreOnboardingTask

/// Main view for the plan settings.
///
/// We might want to consider renaming this group of types to follow the `Subscriptions`
/// wording since we're deactivating the `Upgrades` structure from the app.
///
final class UpgradesHostingController: UIHostingController<UpgradesView> {

    init(siteID: Int64) {
        let viewModel = UpgradesViewModel()
        super.init(rootView: .init(viewModel: viewModel))

        rootView.onReportIssueTapped = { [weak self] in
            self?.showContactSupportForm()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showContactSupportForm() {
        let supportController = SupportFormHostingController(viewModel: .init())
        supportController.show(from: self)
    }
}


struct FeatureDetailsView: View {

    @Environment(\.presentationMode) var presentationMode

    var forFeature: StoreOnboardingTask

    var body: some View {
        HStack {
            Text("Description of the specific feature")
        }
    }
}

/// Main view for the plan settings.
///
struct UpgradesView: View {

    /// Drives the view.
    ///
    @StateObject var viewModel: UpgradesViewModel

    /// Closure to be invoked when the "Report Issue" button is tapped.
    ///
    var onReportIssueTapped: (() -> ())?

    var onUpgradeButtonTapped: (() -> ())?
    /// Present details per feature
    ///
    var onFeatureDescriptionTapped: ((StoreOnboardingTask) -> ())?

    // Present upgrades as sheet for now
    @State var presentingUpgrades = false
    // Present details for each feature
    @State var isFeatureDetailsPresented = false
    //
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            Section(content: {
                Text(Localization.currentPlan(viewModel.planName))
                    .bodyStyle()

            }, header: {
                Text(Localization.subscriptionStatus)
            }, footer: {
                Text(viewModel.planInfo)
            })
            Section(content: {
                Button(Localization.upgradeNow) {
                    viewModel.upgradeNowTapped()
                    onUpgradeButtonTapped?()
                    presentingUpgrades = true
                }
                .sheet(isPresented: $presentingUpgrades, onDismiss: {
                    presentationMode.wrappedValue.dismiss()
                }, content: {
                    InAppPurchasesDebugView()
                })
            })

            VStack(alignment: .leading) {
                Text(Localization.experienceFeatures)
                    .bold()
                    .headlineStyle()

                ForEach(viewModel.freeTrialFeatures, id: \.title) { feature in
                    HStack {
                        // Follows a similar design than StoreOnboardingTaskView:
                        StoreOnboardingTaskView(viewModel: StoreOnboardingTaskViewModel(task: .init(isComplete: false, type: .ftiap)),
                                                showDivider: true,
                                                isRedacted: false,
                                                onTap: { featureDetails in
                            isFeatureDetailsPresented = true
                            onFeatureDescriptionTapped?(featureDetails)
                        })
                        .sheet(isPresented: $isFeatureDetailsPresented, onDismiss: {
                            // This should return to the previous view, not dismiss entirely
                            presentationMode.wrappedValue.dismiss()
                        }, content: {
                            FeatureDetailsView(forFeature: .init(isComplete: false, type: .ftiap))
                        })
                    }
                }
            }
            .renderedIf(viewModel.shouldShowFreeTrialFeatures)

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
        static let experienceFeatures = NSLocalizedString("Experience more of our features and services beyond the app",
                                                    comment: "Title for the features list in the Subscriptions Screen")
        static let cancelTrial = NSLocalizedString("Cancel Free Trial", comment: "Title for the button to cancel a free trial")
        static let upgradeNow = NSLocalizedString("Upgrade Now", comment: "")
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
            UpgradesView(viewModel: .init())
        }
    }
}
