import SwiftUI

/// Hosting controller that wraps the `StoreCreationPlanView`.
final class StoreCreationPlanHostingController: UIHostingController<StoreCreationPlanView> {
    private let onPurchase: () async -> Void
    private let onClose: () -> Void

    init(viewModel: StoreCreationPlanViewModel,
         onPurchase: @escaping () async -> Void,
         onClose: @escaping () -> Void) {
        self.onPurchase = onPurchase
        self.onClose = onClose
        super.init(rootView: StoreCreationPlanView(viewModel: viewModel))

        rootView.onPurchase = { [weak self] in
            await self?.onPurchase()
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border and with a close button to dismiss.
    func configureNavigationBarAppearance() {
        addCloseNavigationBarButton(target: self, action: #selector(closeButtonTapped))

        // If large title is only disabled with `navigationBarTitleDisplayMode(.inline)` in the SwiftUI view,
        // navigating from a screen with large title results in a gap below the navigation bar briefly.
        // Also disabling large title in the hosting controller smoothens the transition.
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .withColorStudio(.wooCommercePurple, shade: .shade90)

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    @objc private func closeButtonTapped() {
        onClose()
    }
}

/// Displays the WPCOM eCommerce plan for purchase during the store creation flow.
struct StoreCreationPlanView: View {
    /// Set in the hosting controller.
    var onPurchase: (() async -> Void) = {}

    let viewModel: StoreCreationPlanViewModel

    @State private var isPurchaseInProgress: Bool = false

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 12) {
                            // Plan name.
                            Text(Localization.planTitle)
                                .fontWeight(.semibold)
                                .font(.title3)
                                .foregroundColor(.white)

                            // Price information.
                            VStack(alignment: .leading, spacing: 0) {
                                Text(viewModel.plan.displayPrice)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(2)
                                    .foregroundColor(.white)
                                    .largeTitleStyle()
                                Text(Localization.priceDuration)
                                    .foregroundColor(Color(.secondaryLabel))
                                    .bodyStyle()
                            }
                        }
                        .padding(.horizontal, insets: .init(top: 0, leading: 24, bottom: 0, trailing: 0))

                        Spacer()

                        Image(uiImage: .storeCreationPlanImage)
                    }

                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(Layout.dividerColor))
                        .padding(.horizontal, insets: Layout.defaultPadding)

                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                            .frame(height: 8)

                        // Header label.
                        Text(Localization.subtitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.white))
                            .titleStyle()

                        Spacer()
                            .frame(height: 16)

                        // Powered by WPCOM.
                        HStack(spacing: 5) {
                            Text(Localization.poweredByWPCOMPrompt)
                                .foregroundColor(Color(.secondaryLabel))
                                .footnoteStyle()
                            Image(uiImage: .wpcomLogoImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 18 * scale)
                        }

                        Spacer()
                            .frame(height: 32)

                        // Plan features.
                        StoreCreationPlanFeaturesView(features: viewModel.features)
                    }
                    .padding(Layout.defaultPadding)
                }
            }

            VStack(spacing: 0) {
                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(Layout.dividerColor))

                // Continue button.
                Button(String(format: Localization.continueButtonTitleFormat, viewModel.plan.displayPrice)) {
                    Task { @MainActor in
                        isPurchaseInProgress = true
                        await onPurchase()
                        isPurchaseInProgress = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPurchaseInProgress))
                .padding(Layout.defaultButtonPadding)

                // Refund information.
                Text(Localization.refundableNote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.secondaryLabel))
                    .footnoteStyle()
                    .padding(.horizontal, insets: Layout.defaultPadding)

                Spacer()
                    .frame(height: 24)
            }
        }
        .background(Color(.withColorStudio(.wooCommercePurple, shade: .shade90)))
        // This screen is using the dark theme for both light and dark modes.
        .environment(\.colorScheme, .dark)
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
        // Hides the back button and shows a close button in the hosting controller instead.
        .navigationBarBackButtonHidden(true)
    }
}

private extension StoreCreationPlanView {
    enum Layout {
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let defaultButtonPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let dividerColor: UIColor = .separator
    }

    enum Localization {
        static let planTitle = NSLocalizedString(
            "eCommerce",
            comment: "Title of the store creation plan on the plan screen.")
        static let priceDuration = NSLocalizedString(
            "/month",
            comment: "The text is preceded by the monthly price on the store creation plan screen.")
        static let subtitle = NSLocalizedString(
            "All the features you need, already built in",
            comment: "Subtitle of the store creation plan screen.")
        static let poweredByWPCOMPrompt = NSLocalizedString(
            "Powered by",
            comment: "The text is followed by a WordPress.com logo on the store creation plan screen.")
        static let continueButtonTitleFormat = NSLocalizedString(
            "Create Store for %1$@/month",
            comment: "Title of the button on the store creation plan view to purchase the plan. " +
            "%1$@ is replaced by the monthly price."
        )
        static let refundableNote = NSLocalizedString(
            "There’s no risk, you can cancel for a full refund within 30 days.",
            comment: "Refund policy under the purchase button on the store creation plan screen."
        )
    }
}

#if DEBUG

/// Only used for `StoreCreationPlanView` preview.
private struct Plan: WPComPlanProduct {
    let displayName: String
    let description: String
    let id: String
    let displayPrice: String
}

struct StoreCreationPlanView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationPlanView(viewModel:
                .init(plan: Plan(displayName: "Debug Monthly",
                                 description: "1 Month of Debug Woo",
                                 id: "debug.woocommerce.ecommerce.monthly",
                                 displayPrice: "$69.99")))
    }
}

#endif
