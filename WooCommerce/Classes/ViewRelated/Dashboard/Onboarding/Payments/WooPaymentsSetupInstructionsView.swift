import SwiftUI

/// Hosting controller for `WooPaymentsSetupInstructionsView`.
///
final class WooPaymentsSetupInstructionsHostingController: UIHostingController<WooPaymentsSetupInstructionsView> {
    init(onContinue: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        super.init(rootView: WooPaymentsSetupInstructionsView(onContinue: onContinue,
                                                              onDismiss: onDismiss))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }
}

/// View with instructions to setup WooCommerce.
struct WooPaymentsSetupInstructionsView: View {
    private let onContinue: () -> Void
    private let onDismiss: () -> Void
    @State private var urlFromInstruction: URL?

    private let instructions: [NSAttributedString] = {
        let font: UIFont = .body
        let foregroundColor: UIColor = .text
        let linkColor: UIColor = .accent
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let instruction1: NSAttributedString = {
            let linkContent = Localization.Instruction.Instruction1.tappableText
            let attributedString = NSMutableAttributedString(
                string: .localizedStringWithFormat(Localization.Instruction.Instruction1.text, linkContent),
                attributes: [.font: font,
                             .foregroundColor: foregroundColor,
                             .paragraphStyle: paragraphStyle,
                ]
            )
            let upgradeLink = NSAttributedString(string: linkContent, attributes: [.font: font,
                                                                                   .foregroundColor: linkColor,
                                                                                   .link: URLs.wpcomAccount])
            attributedString.replaceFirstOccurrence(of: linkContent, with: upgradeLink)
            return attributedString
        }()

        let instruction2 = NSAttributedString(string: Localization.Instruction.instruction2, attributes: [.font: font,
                                                                                                          .foregroundColor: foregroundColor,
                                                                                                          .paragraphStyle: paragraphStyle,
        ])

        return [instruction1,
                instruction2]
    }()

    init(onContinue: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.blockSpacing) {
                VStack(alignment: .leading, spacing: Layout.About.spacing) {
                    /// Woo Payments Logo
                    Image(uiImage: .wooPaymentsBadge)
                        .accessibilityHidden(true)

                    /// About Woo Payments
                    Text(Localization.aboutWooPayments)
                        .bodyStyle()

                    /// Estimated setup time
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Localization.EstimatedSetupTime.title)
                            .subheadlineStyle()

                        Text(Localization.EstimatedSetupTime.value)
                            .bodyStyle()
                    }
                }
                .padding(Layout.About.margin)

                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.separator))
                    .padding(.horizontal, Layout.Instruction.margin)

                /// Instructions
                VStack(alignment: .leading, spacing: Layout.Instruction.spacing) {
                    Text(Localization.beforeYouStartSetup)
                        .fontWeight(.semibold)
                        .font(.title3)

                    ForEach(Array(instructions.enumerated()), id: \.element) { index, content in
                        HStack(alignment: .top, spacing: Layout.Instruction.margin) {
                            Text("\(index + 1)")
                                .bodyStyle()
                                .padding(Layout.Instruction.indexPadding)
                                .background(
                                    Circle()
                                        .foregroundColor(Color(.wooCommercePurple(.shade0)))
                                )

                            AttributedText(content)
                                .environment(\.customOpenURL) { url in
                                    urlFromInstruction = url
                                }
                                .safariSheet(url: $urlFromInstruction)
                        }
                    }
                }
                .padding(.horizontal, Layout.Instruction.margin)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: Layout.ctaBlockSpacing) {
                /// CTA
                Button(Localization.startAction, action: onContinue)
                    .buttonStyle(PrimaryButtonStyle())

                /// Footer notice
                HStack(spacing: Layout.Footer.spacing) {
                    Image(uiImage: .infoOutlineImage)
                        .accessibilityHidden(true)

                    LearnMoreAttributedText(format: Localization.Footer.learnMoreFormat,
                                            tappableLearnMoreText: Localization.Footer.learnMore,
                                            url: URLs.learnMore,
                                            shouldUnderLine: false,
                                            textColor: .text)
                }
            }
            .padding(.horizontal, Layout.Footer.margin)
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) {
                    onDismiss()
                }
                .buttonStyle(TextButtonStyle())
            }
        }
    }
}

private extension WooPaymentsSetupInstructionsView {
    enum Layout {
        enum About {
            static let margin = EdgeInsets(top: 32, leading: 16, bottom: 0, trailing: 16)
            static let spacing: CGFloat = 16
        }

        enum Instruction {
            static let margin: CGFloat = 16
            static let spacing: CGFloat = 16
            static let indexPadding: CGFloat = 12
        }

        static let blockSpacing: CGFloat = 24
        static let dividerHeight: CGFloat = 1

        static let ctaBlockSpacing: CGFloat = 16

        enum Footer {
            static let margin: CGFloat = 16
            static let spacing: CGFloat = 8
        }
    }
    enum Localization {
        static let aboutWooPayments = NSLocalizedString("Manage payments effortlessly with WooPayments all in one place. " +
                                             "Accept cards, Apple Pay, in-person payments, and 135+ currencies, all with zero setup costs or monthly fees.",
                                             comment: "About text shown on the Woo payments setup instructions screen.")

        enum EstimatedSetupTime {
            static let title = NSLocalizedString("Estimated setup time",
                                                 comment: "Estimated setup time title text shown on the Woo payments setup instructions screen.")

            static let value = NSLocalizedString("4-6 minutes",
                                                 comment: "Estimated setup time text shown on the Woo payments setup instructions screen.")
        }

        static let beforeYouStartSetup = NSLocalizedString("Before you start setup",
                                                           comment: "Title for the instructions on the Woo payments setup instructions screen.")

        enum Instruction {
            enum Instruction1 {
                static let text = NSLocalizedString("Your WooPayments notifications will be sent to your WordPress.com account email. " +
                                                            "Prefer a new account? More details here.",
                                                            comment: "First instruction on the Woo payments setup instructions screen.")

                static let tappableText = NSLocalizedString("More details here",
                                                            comment: "Tappable text in the instructions of store onboarding payments "
                                                            + "setup screen that opens a webview.")
            }

            static let instruction2 = NSLocalizedString("We've partnered with Stripe for WooPayments. You'll be directed to Stripe's site for sign-up. " +
                                                            "We'll ask you to verify your business and payment details.",
                                                            comment: "Second instruction on the Woo payments setup instructions screen.")
        }


        static let startAction = NSLocalizedString("Begin Setup",
                                                   comment: "Title on the action button on the Woo payments setup instructions screen.")

        enum Footer {
            static let learnMoreFormat = NSLocalizedString("%1$@ about verifying your information with WooPayments.",
                                                           comment: "%1$@ is a tappable link like \"Learn more\" " +
                                                           "that opens a webview for the user to learn more about verifying information for WooPayments.")

            static let learnMore = NSLocalizedString("Learn more",
                                                     comment: "Tappable text at the bottom of store onboarding payments setup screen that opens a webview.")
        }

        static let cancel = NSLocalizedString("Cancel",
                                              comment: "Title of the dismiss button on the store onboarding payments setup screen.")
    }

    enum URLs {
        static let wpcomAccount = WooConstants.URLs.wooPaymentsStartupGuideConnectWordPressComAccount.asURL()

        static let learnMore = WooConstants.URLs.wooPaymentsKnowYourCustomer.asURL()
    }
}

struct WooPaymentsSetupInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        WooPaymentsSetupInstructionsView(onContinue: {}, onDismiss: {})
    }
}
