import Foundation
import SwiftUI
import Yosemite

/// Hosting controller for `UpgradesView`
/// To be used to display available current plan Subscriptions, available plan Upgrades,
/// and the CTA to upgrade
///
@MainActor
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel(siteID: siteID)
        let subscriptionsViewModel = SubscriptionsViewModel()

        super.init(rootView: UpgradesView(upgradesViewModel: upgradesViewModel,
                                          subscriptionsViewModel: subscriptionsViewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {
    @ObservedObject var upgradesViewModel: UpgradesViewModel
    @ObservedObject var subscriptionsViewModel: SubscriptionsViewModel

    init(upgradesViewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        VStack {
            Group {
                CurrentPlanDetailsView(planName: subscriptionsViewModel.planName, daysLeft: subscriptionsViewModel.planDaysLeft)
                Spacer()
            }
            .renderedIf(upgradesViewModel.upgradeViewState.shouldShowPlanDetailsView)

            switch upgradesViewModel.upgradeViewState {
            case .userNotAllowedToUpgrade:
                NonOwnerUpgradesView()
            case .loading:
                OwnerUpgradesView(upgradePlan: .skeletonPlan(), purchasePlanAction: {}, isLoading: true)
            case .loaded(let plan):
                OwnerUpgradesView(upgradePlan: plan, purchasePlanAction: {
                    Task {
                        await upgradesViewModel.purchasePlan(with: plan.wpComPlan.id)
                    }
                })
            case .purchasing(let plan):
                OwnerUpgradesView(upgradePlan: plan, isPurchasing: true, purchasePlanAction: {})
            case .waiting(let plan):
                UpgradeWaitingView(planName: plan.wooPlan.shortName)
            case .completed:
                EmptyCompletedView()
            default:
                EmptyView()
            }
        }
        .navigationBarTitle(UpgradesView.Localization.navigationTitle)
        .padding(.top)
    }
}

struct UpgradeWaitingView: View {
    let planName: String

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                ProgressView()
                    .progressViewStyle(IndefiniteCircularProgressViewStyle(size: Layout.progressIndicatorSize,
                                                                           lineWidth: Layout.progressIndicatorLineWidth))
                VStack(alignment: .leading, spacing: Layout.textSpacing) {
                    Text(Localization.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(String(format: Localization.descriptionFormatString, planName))
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)

            Spacer()
        }
    }
}

private extension UpgradeWaitingView {
    enum Localization {
        static let title = NSLocalizedString("You’re almost there",
                                             comment: "Title for the progress screen shown after an In-App Purchase " +
                                             "for a Woo Express plan, while we upgrade the site.")

        static let descriptionFormatString = NSLocalizedString(
            "Please bear with us while we process the payment for your %1$@ plan.",
            comment: "Detail text shown after an In-App Purchase for a Woo Express plan, shown while we upgrade the " +
            "site. %1$@ is replaced with the short plan name. " +
            "Reads as: 'Please bear with us while we process the payment for your Essential plan.'")
    }

    enum Layout {
        static let progressIndicatorSize: CGFloat = 56
        static let progressIndicatorLineWidth: CGFloat = 6
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 80
        static let spacing: CGFloat = 40
        static let textSpacing: CGFloat = 16
    }
}

struct EmptyCompletedView: View {
    var body: some View {
        Text("Completed!")
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

                    VStack(alignment: .leading) {
                        Text(upgradePlan.wooPlan.shortName)
                            .font(.largeTitle)
                        Text(upgradePlan.wooPlan.planDescription)
                            .font(.subheadline)
                    }

                    VStack(alignment: .leading) {
                        Text(upgradePlan.wpComPlan.displayPrice)
                            .font(.largeTitle)
                        Text(upgradePlan.wooPlan.planFrequency.localizedString)
                            .font(.footnote)
                    }
                }
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

struct NonOwnerUpgradesView: View {
    private var siteName: String? {
        ServiceLocator.stores.sessionManager.defaultSite?.name
    }

    var body: some View {
        VStack {
            Spacer()

            Image(uiImage: .noStoreImage)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            VStack(alignment: .center, spacing: UpgradesView.Layout.contentSpacing) {
                Text(Localization.unableToUpgradeText)
                    .bold()
                    .headlineStyle()
                if let siteName = siteName {
                    Text(siteName)
                }
                Text(Localization.unableToUpgradeInstructions)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

private struct CurrentPlanDetailsView: View {
    @State var planName: String
    @State var daysLeft: String

    private var daysLeftText: String {
        String.localizedStringWithFormat(Localization.daysLeftValue, daysLeft)
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

        static let daysLeftValue = NSLocalizedString(
            "%1$@ days left", comment: "Value describing the days left on a plan before expiry. Reads as '15 days left'")
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

private extension NonOwnerUpgradesView {
    struct Localization {
        static let unableToUpgradeText = NSLocalizedString("Unable to upgrade",
                                                           comment: "Text describing that is not possible to upgrade the site's plan.")
        static let unableToUpgradeInstructions = NSLocalizedString("Only the site owner can manage upgrades",
                                                                   comment: "Text describing that only the site owner can upgrade the site's plan.")
    }
}

private extension UpgradesView {
    struct Localization {
        static let navigationTitle = NSLocalizedString("Plans", comment: "Navigation title for the Upgrades screen")
    }

    struct Layout {
        static let contentSpacing: CGFloat = 8
        static let smallPadding: CGFloat = 8
    }
}
