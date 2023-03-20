import SwiftUI

/// Hosting controller that wraps the `StoreOnboardingPaymentsSetupView`.
final class StoreOnboardingPaymentsSetupHostingController: UIHostingController<StoreOnboardingPaymentsSetupView> {
    init(task: StoreOnboardingPaymentsSetupCoordinator.Task,
         onContinue: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        super.init(rootView: StoreOnboardingPaymentsSetupView(task: task,
                                                              onContinue: onContinue,
                                                              onDismiss: onDismiss))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows an overview of the payments setup with a CTA to set up payments in a webview.
struct StoreOnboardingPaymentsSetupView: View {
    typealias Task = StoreOnboardingPaymentsSetupCoordinator.Task

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var urlToOpen: URL?

    private let task: Task
    private let onContinue: () -> Void
    private let onDismiss: () -> Void

    init(task: Task,
         onContinue: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        self.task = task
        self.onContinue = onContinue
        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                HStack {
                    Circle()
                        .fill(Color(.wooCommercePurple(.shade0)))
                        .frame(width: Layout.circleDimension * scale, height: Layout.circleDimension * scale)
                        .overlay {
                            Image(uiImage: .currencyImage)
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(.brand))
                                .frame(width: Layout.circleDimension * scale * 0.5, height: Layout.circleDimension * scale * 0.5)
                        }
                    Spacer()
                }

                Text(task.attributedHeader)
                    .bold()

                Text(.init(task.details))
                    .tint(Color(.accent))
                    .bodyStyle()
                    .environment(\.openURL, OpenURLAction { url in
                        urlToOpen = url
                        return .handled
                    })
                    .safariSheet(url: $urlToOpen)
            }
            .padding(Layout.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                    .dividerStyle()

                VStack(spacing: Layout.defaultSpacing) {
                    // Continue button.
                    Button(Localization.continueButtonTitle) {
                        onContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    // Learn more button.
                    Button(Localization.learnMoreButtonTitle) {
                        urlToOpen = task.learnMoreURL
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(insets: Layout.buttonContainerPadding)
            }
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Localization.dismiss) {
                    onDismiss()
                }
                .buttonStyle(TextButtonStyle())
            }
        }
    }
}

private extension StoreOnboardingPaymentsSetupView {
    enum Layout {
        static let contentPadding: EdgeInsets = .init(top: 76, leading: 16, bottom: 16, trailing: 16)
        static let buttonContainerPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let defaultSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 24
        static let circleDimension: CGFloat = 120
    }

    enum Localization {
        static let continueButtonTitle = NSLocalizedString(
            "Continue Setup",
            comment: "Title of the primary button on the store onboarding payments setup screen."
        )
        static let learnMoreButtonTitle = NSLocalizedString(
            "Learn More",
            comment: "Title of the secondary button on the store onboarding payments setup screen."
        )
        static let dismiss = NSLocalizedString(
            "Cancel",
            comment: "Title of the dismiss button on the store onboarding payments setup screen."
        )
    }
}

private extension StoreOnboardingPaymentsSetupView.Task {
    var headerFormat: String {
        NSLocalizedString(
            "Set up %1$@",
            comment: "Header text format on the store onboarding WCPay/payments setup screen. " +
            "%1$@ can be 'WooCommerce Payments' when WCPay is available or 'Payment Methods.'"
        )
    }

    var highlightedInHeader: String {
        switch self {
        case .wcPay:
            return NSLocalizedString(
                "WooCommerce Payments",
                comment: "Highlighted header text on the store onboarding WCPay setup screen."
            )
        case .payments:
            return NSLocalizedString(
                "Payment Methods",
                comment: "Highlighted header text on the store onboarding payments setup screen."
            )
        }
    }

    var attributedHeader: AttributedString {
        var attributedText = AttributedString(.init(format: headerFormat, highlightedInHeader))
        attributedText.font = .title1
        attributedText.foregroundColor = .init(.text)

        // Styles for the highlighted string.
        if let range = attributedText.range(of: highlightedInHeader) {
            let highlightedContainer = AttributeContainer()
                .foregroundColor(.init(uiColor: .wooCommercePurple(.shade50)))
            attributedText[range].mergeAttributes(highlightedContainer)
        }
        return attributedText
    }

    var details: String {
        switch self {
        case .wcPay:
            return NSLocalizedString(
                "By using WooCommerce Payments you agree to be bound by our " +
                "[Terms of Service](https://wordpress.com/tos) and acknowledge that " +
                "you have read our [Privacy Policy](https://automattic.com/privacy/).",
                comment: "Details on the store onboarding WCPay setup screen."
            )
        case .payments:
            return NSLocalizedString(
                "Discover other payment providers and choose a payment provider.",
                comment: "Details on the store onboarding payments setup screen."
            )
        }
    }

    var learnMoreURL: URL {
        let urlString: String
        switch self {
        case .wcPay:
            urlString = "https://woocommerce.com/document/woocommerce-payments/startup-guide"
        case .payments:
            urlString = "https://woocommerce.com/documentation/woocommerce/getting-started/sell-products/core-payment-options"
        }
        guard let url = URL(string: urlString) else {
            fatalError("Unexpected URL: \(urlString)")
        }
        return url
    }
}

struct StoreOnboardingPaymentsSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreOnboardingPaymentsSetupView(task: .wcPay, onContinue: {}, onDismiss: {})
        }
        NavigationView {
            StoreOnboardingPaymentsSetupView(task: .payments, onContinue: {}, onDismiss: {})
        }
    }
}
