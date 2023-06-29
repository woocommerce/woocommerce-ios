import Foundation
import SwiftUI
import Yosemite

/// Hosting controller for `UpgradesView`
/// To be used to display available current plan Subscriptions, available plan Upgrades,
/// and the CTA to upgrade
///
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    private let authentication: Authentication = ServiceLocator.authenticationManager

    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel(siteID: siteID)
        let subscriptionsViewModel = SubscriptionsViewModel()

        super.init(rootView: UpgradesView(upgradesViewModel: upgradesViewModel, subscriptionsViewModel: subscriptionsViewModel))

        rootView.supportHandler = { [weak self] in
            self?.openSupport()
        }
    }

    func openSupport() {
        authentication.presentSupport(from: self, screen: .purchasePlanError)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var upgradesViewModel: UpgradesViewModel
    @ObservedObject var subscriptionsViewModel: SubscriptionsViewModel

    var supportHandler: () -> Void = {}

    init(upgradesViewModel: UpgradesViewModel,
         subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    // TODO: Once we remove iOS 15 support, we can do this with .toolbar instead.
                    UpgradeTopBarView(dismiss: {
                        dismiss()
                    })

                    CurrentPlanDetailsView(planName: subscriptionsViewModel.planName,
                                           daysLeft: subscriptionsViewModel.planDaysLeft)
                }
                .renderedIf(upgradesViewModel.upgradeViewState.shouldShowPlanDetailsView)

                switch upgradesViewModel.upgradeViewState {
                case .loading:
                    OwnerUpgradesView(upgradePlan: .skeletonPlan(), purchasePlanAction: {}, isLoading: true)
                        .accessibilityLabel(Localization.plansLoadingAccessibilityLabel)
                case .loaded(let plan):
                    OwnerUpgradesView(upgradePlan: plan, purchasePlanAction: {
                        Task {
                            await upgradesViewModel.purchasePlan(with: plan.wpComPlan.id)
                        }
                    })
                case .purchasing(let plan):
                    OwnerUpgradesView(upgradePlan: plan, isPurchasing: true, purchasePlanAction: {})
                case .waiting(let plan):
                    ScrollView(.vertical) {
                        UpgradeWaitingView(planName: plan.wooPlan.shortName)
                    }
                case .completed(let plan):
                    CompletedUpgradeView(planName: plan.wooPlan.shortName,
                                         doneAction: {
                        dismiss()
                    })
                case .prePurchaseError(let error):
                    ScrollView(.vertical) {
                        VStack {
                            PrePurchaseUpgradesErrorView(error,
                                                         onRetryButtonTapped: {
                                upgradesViewModel.retryFetch()
                            })
                            .padding(.top, Layout.errorViewTopPadding)
                            .padding(.horizontal, Layout.errorViewHorizontalPadding)

                            Spacer()
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                case .purchaseUpgradeError(.inAppPurchaseFailed(let plan, let iapStoreError)):
                    PurchaseUpgradeErrorView(error: .inAppPurchaseFailed(plan, iapStoreError)) {
                        Task {
                            await upgradesViewModel.purchasePlan(with: plan.wpComPlan.id)
                        }
                    } secondaryAction: {
                        dismiss()
                    } getSupportAction: {
                        supportHandler()
                    }
                case .purchaseUpgradeError(let underlyingError):
                    // handles .planActivationFailed and .unknown underlyingErrors
                    PurchaseUpgradeErrorView(error: underlyingError,
                                             primaryAction: nil,
                                             secondaryAction: {
                        dismiss()
                    },
                                             getSupportAction: supportHandler)
                }
            }
            .navigationBarHidden(true)
        }
        // TODO: when we remove iOS 15 support, use NavigationStack instead.
        // This is required to avoid a column layout on iPad, which looks strange.
        .navigationViewStyle(.stack)
        .onDisappear {
            upgradesViewModel.onDisappear()
        }
    }
}

struct CompletedUpgradeView: View {
    // Confetti animation runs on any change of this variable
    @State private var confettiTrigger: Int = 0

    let planName: String

    let doneAction: (() -> Void)

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(spacing: Layout.groupSpacing) {
                    Image("plan-upgrade-success-celebration")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityHidden(true)

                    VStack(spacing: Layout.textSpacing) {
                        Text(Localization.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(LocalizedString(format: Localization.subtitle, planName))
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(Localization.hint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Layout.completedUpgradeViewTopPadding)
                .padding(.horizontal, Layout.padding)
            }

            Spacer()

            Button(Localization.doneButtonText) {
                doneAction()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.padding)
        }
        .confettiCannon(counter: $confettiTrigger,
                        num: Constants.numberOfConfettiElements,
                        colors: [.withColorStudio(name: .wooCommercePurple, shade: .shade10),
                                 .withColorStudio(name: .wooCommercePurple, shade: .shade30),
                                 .withColorStudio(name: .wooCommercePurple, shade: .shade70),
                                 .withColorStudio(name: .wooCommercePurple, shade: .shade80)],
                        radius: Constants.confettiRadius)
        .onAppear {
            confettiTrigger += 1
        }
        .padding(.bottom, Layout.padding)
    }

    private struct Layout {
        static let completedUpgradeViewTopPadding: CGFloat = 70
        static let padding: CGFloat = 16
        static let groupSpacing: CGFloat = 32
        static let textSpacing: CGFloat = 16
    }

    private struct Constants {
        static let numberOfConfettiElements: Int = 100
        static let confettiRadius: CGFloat = 500
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "Woo! You’re off to a great start!", comment: "Text shown when a plan upgrade has been successfully purchased.")
        static let subtitle = NSLocalizedString(
            "Your purchase is complete and you're on the %1$@ plan.",
            comment: "Additional text shown when a plan upgrade has been successfully purchased. %1$@ is replaced by " +
            "the plan name, and should be included in the translated string.")
        static let hint = NSLocalizedString(
            "You can manage your subscription in your iPhone Settings → Your Name → Subscriptions", comment: "Instructions" +
            " guiding the merchant to manage a site's plan upgrade.")
        static let doneButtonText = NSLocalizedString(
            "Done", comment: "Done button on the screen that is shown after a successful plan upgrade.")
    }
}

struct OwnerUpgradesView: View {
    @State var upgradePlan: WooWPComPlan
    @State var isPurchasing = false
    let purchasePlanAction: () -> Void
    @State var isLoading: Bool = false

    var body: some View {
        VStack {
            List {
                Section {
                    Image(upgradePlan.wooPlan.headerImageFileName)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(.zero)
                        .listRowBackground(upgradePlan.wooPlan.headerImageCardColor)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading) {
                        Text(upgradePlan.wooPlan.shortName)
                            .font(.largeTitle)
                            .accessibilityAddTraits(.isHeader)
                        Text(upgradePlan.wooPlan.planDescription)
                            .font(.subheadline)
                    }

                    VStack(alignment: .leading) {
                        Text(upgradePlan.wpComPlan.displayPrice)
                            .font(.largeTitle)
                            .accessibilityAddTraits(.isHeader)
                        Text(upgradePlan.wooPlan.planFrequency.localizedString)
                            .font(.footnote)
                    }
                }
                .accessibilityAddTraits(.isSummaryElement)
                .listRowSeparator(.hidden)

                if upgradePlan.hardcodedPlanDataIsValid {
                    Section {
                        ForEach(upgradePlan.wooPlan.planFeatureGroups, id: \.title) { featureGroup in
                            NavigationLink(destination: WooPlanFeatureBenefitsView(wooPlanFeatureGroup: featureGroup)) {
                                WooPlanFeatureGroupRow(featureGroup: featureGroup)
                            }
                            .disabled(isLoading)
                        }
                    } header: {
                        Text(String.localizedStringWithFormat(Localization.featuresHeaderTextFormat, upgradePlan.wooPlan.shortName))
                    }
                    .headerProminence(.increased)
                } else {
                    NavigationLink(destination: {
                        /// Note that this is a fallback only, and we should remove it once we load feature details remotely.
                        AuthenticatedWebView(isPresented: .constant(true),
                                             url: WooConstants.URLs.fallbackWooExpressHome.asURL())
                    }, label: {
                        Text(Localization.featureDetailsUnavailableText)
                    })
                    .disabled(isLoading)
                }
            }
            .listStyle(.insetGrouped)
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            VStack {
                let buttonText = String.localizedStringWithFormat(Localization.purchaseCTAButtonText, upgradePlan.wpComPlan.displayName)
                Button(buttonText) {
                    purchasePlanAction()
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPurchasing))
                .disabled(isLoading)
                .redacted(reason: isLoading ? .placeholder : [])
                .shimmering(active: isLoading)
            }
            .padding()
        }
    }
}

private extension WooWPComPlan {
    static func skeletonPlan() -> WooWPComPlan {
        return WooWPComPlan(
            wpComPlan: SkeletonWPComPlanProduct(),
            wooPlan: WooPlan(id: "skeleton.plan.monthly",
                             name: "Skeleton Plan Monthly",
                             shortName: "Skeleton",
                             planFrequency: .month,
                             planDescription: "A skeleton plan to show (redacted) while we're loading",
                             headerImageFileName: "express-essential-header",
                             headerImageCardColor: .withColorStudio(name: .orange, shade: .shade5),
                             planFeatureGroups: [
                                WooPlanFeatureGroup(title: "Feature group 1",
                                                    description: "A feature description with a realistic length to " +
                                                    "ensure the cell looks correct when redacted",
                                                    imageFilename: "",
                                                    imageCardColor: .withColorStudio(name: .blue, shade: .shade5),
                                                    features: []),
                                WooPlanFeatureGroup(title: "Feature group 2",
                                                    description: "A feature description with a realistic length to " +
                                                    "ensure the cell looks correct when redacted",
                                                    imageFilename: "",
                                                    imageCardColor: .withColorStudio(name: .green, shade: .shade5),
                                                    features: []),
                                WooPlanFeatureGroup(title: "Feature group 3",
                                                    description: "A feature description with a realistic length to " +
                                                    "ensure the cell looks correct when redacted",
                                                    imageFilename: "",
                                                    imageCardColor: .withColorStudio(name: .pink, shade: .shade5),
                                                    features: []),
                             ]),
            hardcodedPlanDataIsValid: true)
    }

    private struct SkeletonWPComPlanProduct: WPComPlanProduct {
        let displayName: String = "Skeleton Plan Monthly"
        let description: String = "A skeleton plan to show (redacted) while we're loading"
        let id: String = "skeleton.wpcom.plan.product"
        let displayPrice: String = "$39"
    }
}

private struct CurrentPlanDetailsView: View {
    @State var planName: String
    @State var daysLeft: Int?

    private var daysLeftText: String {
        guard let daysLeft else {
            return ""
        }
        return String.pluralize(daysLeft,
                                singular: Localization.daysLeftValueSingular,
                                plural: Localization.daysLeftValuePlural)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UpgradesView.Layout.contentSpacing) {
            HStack {
                Text(Localization.yourPlanLabel)
                    .font(.footnote)
                Spacer()
                Text(planName)
                    .font(.footnote.bold())
            }
            HStack {
                Text(Localization.daysLeftLabel)
                    .font(.footnote)
                Spacer()
                Text(daysLeftText)
                    .font(.footnote.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing])
        .padding(.vertical, UpgradesView.Layout.smallPadding)
    }

    private enum Localization {
        static let yourPlanLabel = NSLocalizedString(
            "Your plan", comment: "Label for the text describing which Plan the merchant is currently subscribed to." +
            "Reads as 'Your Plan: Free Trial'")

        static let daysLeftLabel = NSLocalizedString(
            "Days left in plan", comment: "Label for the text describing days left on a Plan to expire." +
            "Reads as 'Days left in plan: 15 days left'")

        static let daysLeftValuePlural = NSLocalizedString(
            "%1ld days left", comment: "Value describing the days left on a plan before expiry (plural). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '15 days left'")

        static let daysLeftValueSingular = NSLocalizedString(
            "%1$ld day left", comment: "Value describing the days left on a plan before expiry (singular). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '1 day left'")
    }
}

private struct UpgradeTopBarView: View {
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Text(Localization.navigationTitle)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .leading) {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: Layout.closeButtonSize))
                    .foregroundColor(Color(.label))
                    .padding()
                    .frame(alignment: .leading)
            }
        }
    }

    private enum Localization {
        static let navigationTitle = NSLocalizedString("Upgrade", comment: "Navigation title for the Upgrades screen")
    }

    private enum Layout {
        static let closeButtonSize: CGFloat = 16
    }
}

struct UpgradesView_Preview: PreviewProvider {
    static var previews: some View {
        UpgradesView(upgradesViewModel: UpgradesViewModel(siteID: 0),
                     subscriptionsViewModel: SubscriptionsViewModel())
    }
}

private extension OwnerUpgradesView {
    struct Localization {
        static let purchaseCTAButtonText = NSLocalizedString("Purchase %1$@", comment: "The title of the button to purchase a Plan." +
                                                             "Reads as 'Purchase Essential Monthly'")
        static let featuresHeaderTextFormat = NSLocalizedString(
            "Get the most out of %1$@",
            comment: "Title for the section header for the list of feature categories on the Upgrade plan screen. " +
            "Reads as 'Get the most out of Essential'. %1$@ must be included in the string and will be replaced with " +
            "the plan name.")

        static let featureDetailsUnavailableText = NSLocalizedString(
            "See plan details", comment: "Title for a link to view Woo Express plan details on the web, as a fallback.")
    }
}

private extension UpgradesView {
    struct Layout {
        static let errorViewHorizontalPadding: CGFloat = 20
        static let errorViewTopPadding: CGFloat = 36
        static let padding: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let smallPadding: CGFloat = 8
    }

    enum Localization {
        static let plansLoadingAccessibilityLabel = NSLocalizedString(
            "Loading plan details",
            comment: "Accessibility label for the initial loading state of the Upgrades view")
    }
}
