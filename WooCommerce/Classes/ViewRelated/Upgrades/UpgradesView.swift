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

struct PrePurchaseUpgradesErrorView: View {

    private let error: PrePurchaseError

    /// Closure invoked when the "Retry" button is tapped
    ///
    var onRetryButtonTapped: (() -> Void)

    init(_ error: PrePurchaseError,
         onRetryButtonTapped: @escaping (() -> Void)) {
        self.error = error
        self.onRetryButtonTapped = onRetryButtonTapped
    }

    var body: some View {
        VStack(alignment: .center, spacing: Layout.spacingBetweenImageAndText) {
            Image("plan-upgrade-error")
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: Layout.textSpacing) {
                switch error {
                case .fetchError, .entitlementsError:
                    VStack(alignment: .center) {
                        Text(Localization.fetchErrorMessage)
                            .bold()
                            .headlineStyle()
                            .multilineTextAlignment(.center)
                        Button(Localization.retry) {
                            onRetryButtonTapped()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .fixedSize(horizontal: true, vertical: true)
                    }
                case .maximumSitesUpgraded:
                    Text(Localization.maximumSitesUpgradedErrorMessage)
                        .bold()
                        .headlineStyle()
                        .multilineTextAlignment(.center)
                    Text(Localization.maximumSitesUpgradedErrorSubtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                case .inAppPurchasesNotSupported:
                    Text(Localization.inAppPurchasesNotSupportedErrorMessage)
                        .bold()
                        .headlineStyle()
                        .multilineTextAlignment(.center)
                    Text(Localization.inAppPurchasesNotSupportedErrorSubtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                case .userNotAllowedToUpgrade:
                    Text(Localization.unableToUpgradeText)
                        .bold()
                        .headlineStyle()
                        .multilineTextAlignment(.center)
                    Text(Localization.unableToUpgradeInstructions)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, Layout.horizontalEdgesPadding)
        .padding(.vertical, Layout.verticalEdgesPadding)
        .background {
            RoundedRectangle(cornerSize: .init(width: Layout.cornerRadius, height: Layout.cornerRadius))
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    private enum Layout {
        static let horizontalEdgesPadding: CGFloat = 16
        static let verticalEdgesPadding: CGFloat = 40
        static let cornerRadius: CGFloat = 12
        static let spacingBetweenImageAndText: CGFloat = 32
        static let textSpacing: CGFloat = 16
    }

    private enum Localization {
        static let retry = NSLocalizedString(
            "Retry", comment: "Title of the button to attempt a retry when fetching or purchasing plans fails.")

        static let fetchErrorMessage = NSLocalizedString(
            "We encountered an error loading plan information", comment: "Error message displayed when " +
            "we're unable to fetch In-App Purchases plans from the server.")

        static let maximumSitesUpgradedErrorMessage = NSLocalizedString(
            "A WooCommerce app store subscription with your Apple ID already exists",
            comment: "Error message displayed when the merchant already has one store upgraded under the same Apple ID.")

        static let maximumSitesUpgradedErrorSubtitle = NSLocalizedString(
            "An Apple ID can only be used to upgrade one store",
            comment: "Subtitle message displayed when the merchant already has one store upgraded under the same Apple ID.")

        static let cancelUpgradeButtonText = NSLocalizedString(
            "Cancel Upgrade",
            comment: "Title of the button displayed when purchasing a plan fails, so the flow can be cancelled.")

        static let inAppPurchasesNotSupportedErrorMessage = NSLocalizedString(
            "In-App Purchases not supported",
            comment: "Error message displayed when In-App Purchases are not supported.")

        static let inAppPurchasesNotSupportedErrorSubtitle = NSLocalizedString(
            "Please contact support for assistance.",
            comment: "Subtitle message displayed when In-App Purchases are not supported, redirecting to contact support if needed.")

        static let unableToUpgradeText = NSLocalizedString(
            "You can’t upgrade because you are not the store owner",
            comment: "Text describing that is not possible to upgrade the site's plan.")

        static let unableToUpgradeInstructions = NSLocalizedString(
            "Please contact the store owner to upgrade your plan.",
            comment: "Text describing that only the site owner can upgrade the site's plan.")
    }
}

struct PurchaseUpgradeErrorView: View {
    let error: PurchaseUpgradeError
    let primaryAction: (() -> Void)?
    let secondaryAction: (() -> Void)
    let getSupportAction: (() -> Void)

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: Layout.spacing) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: Layout.exclamationImageSize))
                        .foregroundColor(.withColorStudio(name: .red, shade: .shade20))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Layout.textSpacing) {
                        Text(error.localizedTitle)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(error.localizedDescription)
                        Text(error.localizedActionDirection)
                            .font(.title3)
                            .fontWeight(.bold)
                        if let actionHint = error.localizedActionHint {
                            Text(actionHint)
                                .font(.footnote)
                        }
                        if let errorCode = error.localizedErrorCode {
                            Text(String(format: Localization.errorCodeFormat, errorCode))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Button(action: getSupportAction) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.withColorStudio(name: .blue, shade: .shade50))
                                Text(Localization.getSupport)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.withColorStudio(name: .blue, shade: .shade50))
                            }
                        }
                    }
                }
                .padding(.top, Layout.topPadding)
                .padding(.horizontal, Layout.horizontalPadding)
            }

            Spacer()

            if let primaryButtonTitle = error.localizedPrimaryButtonLabel {
                Button(primaryButtonTitle) {
                    primaryAction?()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.horizontalPadding)
            }

            Button(error.localizedSecondaryButtonTitle) {
                secondaryAction()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(.bottom)
    }

    enum Layout {
        static let exclamationImageSize: CGFloat = 56
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 80
        static let spacing: CGFloat = 40
        static let textSpacing: CGFloat = 16
    }

    enum Localization {
        static let getSupport = NSLocalizedString(
            "Get support",
            comment: "Button title to allow merchants to open the support screens when there's an error with their plan purchase")
        static let errorCodeFormat = NSLocalizedString(
            "Error code %1$@",
            comment: "A string shown on the error screen when there's an issue purchasing a plan, to inform the user " +
            "of the error code for use with Support. %1$@ will be replaced with the error code and must be included " +
            "in the translations.")
    }
}

private extension PurchaseUpgradeError {
    var localizedTitle: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorTitle
        case .planActivationFailed:
            return Localization.activationErrorTitle
        case .unknown:
            return Localization.unknownErrorTitle
        }
    }

    var localizedDescription: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorDescription
        case .planActivationFailed:
            return Localization.activationErrorDescription
        case .unknown:
            return Localization.unknownErrorDescription
        }
    }

    var localizedActionDirection: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorActionDirection
        case .planActivationFailed, .unknown:
            return Localization.errorContactSupportActionDirection
        }
    }

    var localizedActionHint: String? {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorActionHint
        case .planActivationFailed:
            return nil
        case .unknown:
            return nil
        }
    }

    var localizedErrorCode: String? {
        switch self {
        case .inAppPurchaseFailed(_, let underlyingError), .planActivationFailed(let underlyingError):
            return underlyingError.errorCode
        case .unknown:
            return nil
        }
    }

    var localizedPrimaryButtonLabel: String? {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.retryPaymentButtonText
        case .planActivationFailed:
            return nil
        case .unknown:
            return nil
        }
    }

    var localizedSecondaryButtonTitle: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.cancelUpgradeButtonText
        case .planActivationFailed, .unknown:
            return Localization.returnToMyStoreButtonText
        }
    }

    private enum Localization {
        /// Purchase errors
        static let purchaseErrorTitle = NSLocalizedString(
            "Error confirming payment",
            comment: "Error message displayed when a payment fails when attempting to purchase a plan.")

        static let purchaseErrorDescription = NSLocalizedString(
            "We encountered an error confirming your payment.",
            comment: "Error description displayed when a payment fails when attempting to purchase a plan.")

        static let purchaseErrorActionDirection = NSLocalizedString(
            "No payment has been taken",
            comment: "Bolded message confirming that no payment has been taken when the upgrade failed.")

        static let purchaseErrorActionHint = NSLocalizedString(
            "Please try again, or contact support for assistance",
            comment: "Subtitle message displayed when the merchant already has one store upgraded under the same Apple ID.")

        static let retryPaymentButtonText = NSLocalizedString(
            "Try Payment Again",
            comment: "Title of the button displayed when purchasing a plan fails, so the merchant can try again.")

        static let cancelUpgradeButtonText = NSLocalizedString(
            "Cancel Upgrade",
            comment: "Title of the secondary button displayed when purchasing a plan fails, so the merchant can exit the flow.")

        /// Upgrade errors
        static let activationErrorTitle = NSLocalizedString(
            "Error activating plan",
            comment: "Error message displayed when plan activation fails after purchasing a plan.")

        static let activationErrorDescription = NSLocalizedString(
            "Your subscription is active, but there was an error activating the plan on your store.",
            comment: "Error description displayed when plan activation fails after purchasing a plan.")

        static let errorContactSupportActionDirection = NSLocalizedString(
            "Please contact support for assistance.",
            comment: "Bolded message advising the merchant to contact support when the plan activation failed.")

        static let returnToMyStoreButtonText = NSLocalizedString(
            "Return to My Store",
            comment: "Title of the secondary button displayed when activating the purchased plan fails, so the merchant can exit the flow.")

        /// Unknown errors
        static let unknownErrorTitle = NSLocalizedString(
            "Error during purchase",
            comment: "Title of an unknown error after purchasing a plan")

        static let unknownErrorDescription = NSLocalizedString(
            "Something went wrong during your purchase, and we can't tell whether your payment has completed, or your store plan been upgraded.",
            comment: "Description of an unknown error after purchasing a plan")
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
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(format: Localization.descriptionFormatString, planName))
                        .fixedSize(horizontal: false, vertical: true)
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
        static let verticalPadding: CGFloat = 152
        static let spacing: CGFloat = 40
        static let textSpacing: CGFloat = 16
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
