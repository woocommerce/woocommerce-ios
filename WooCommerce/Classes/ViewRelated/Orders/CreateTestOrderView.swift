import SwiftUI

/// Hosting controller for `CreateTestOrderView`.
///
final class CreateTestOrderHostingController: UIHostingController<CreateTestOrderView> {
    init(createTestOrderHandler: @escaping () -> Void) {
        super.init(rootView: CreateTestOrderView(createTestOrderHandler: createTestOrderHandler))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

private extension CreateTestOrderHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
    }
}

/// View with instructions to create a test order.
struct CreateTestOrderView: View {

    private let createTestOrderHandler: () -> Void

    private let instructions: [String] = [
        Localization.instruction1,
        Localization.instruction2,
        Localization.instruction3,
        Localization.instruction4
    ]

    init(createTestOrderHandler: @escaping () -> Void) {
        self.createTestOrderHandler = createTestOrderHandler
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.blockSpacing) {
                /// Title
                Text(Localization.title)
                    .titleStyle()

                /// Image
                Image(uiImage: .createOrderImage)

                /// Instructions
                VStack(alignment: .leading, spacing: Layout.instructionSpacing) {
                    ForEach(Array(instructions.enumerated()), id: \.element) { index, content in
                        HStack(spacing: Layout.instructionMargin) {
                            Text("\(index + 1)")
                                .bodyStyle()
                                .padding(Layout.instructionIndexPadding)
                                .background(
                                    Circle()
                                        .foregroundColor(.init(uiColor: UIColor(light: .systemGroupedBackground,
                                                                                dark: .secondarySystemGroupedBackground)))
                                )
                            if index == instructions.count - 1 {
                                /// Last step embeds a tappable link to the non-refundable fees documentation,
                                /// while keeping the same base font and color as the other steps.
                                CreateTestOrderInstructionWithLink(
                                    format: content,
                                    linkText: Localization.feesNotRefundable,
                                    url: WooConstants.URLs.wooPaymentsFeesNotRefundable.asURL()
                                )
                            } else {
                                Text(content)
                                    .font(.subheadline)
                                    .foregroundColor(.init(uiColor: .text))
                            }
                        }
                    }
                    .padding(.horizontal, Layout.instructionMargin)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                /// CTA
                Button(Localization.startAction, action: createTestOrderHandler)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Layout.buttonMargin)
            }
            .background(Color(.systemBackground))
        }
    }
}

/// An instruction step whose base text matches the other steps (`.subheadline`, `.text`),
/// with a single tappable substring that opens the given URL in an in-app Safari sheet.
private struct CreateTestOrderInstructionWithLink: View {
    private let attributedText: AttributedString
    @State private var safariURL: URL?

    /// - Parameters:
    ///   - format: A format string with a single `%1$@` placeholder for the tappable text.
    ///   - linkText: The tappable substring that opens the Safari sheet.
    ///   - url: The URL to display in the Safari sheet when the link is tapped.
    init(format: String, linkText: String, url: URL) {
        attributedText = {
            var text = AttributedString(.init(format: format, linkText))
            text.font = .subheadline
            text.foregroundColor = .init(uiColor: .text)

            if let range = text.range(of: linkText) {
                text[range].link = url
                text[range].foregroundColor = .init(uiColor: .accent)
                text[range].underlineStyle = .single
            }
            return text
        }()
    }

    var body: some View {
        Text(attributedText)
            .environment(\.openURL, OpenURLAction { url in
                safariURL = url
                return .handled
            })
            .safariSheet(url: $safariURL)
    }
}

private extension CreateTestOrderView {
    enum Layout {
        static let instructionMargin: CGFloat = 24
        static let instructionSpacing: CGFloat = 16
        static let instructionIndexPadding: CGFloat = 12
        static let buttonMargin: CGFloat = 16
        static let blockSpacing: CGFloat = 32
    }
    enum Localization {
        static let title = NSLocalizedString("Place your first order", comment: "Title shown on the test order screen")
        static let instruction1 = NSLocalizedString(
            "Tap the button below to be redirected to your online store via a web browser.",
            comment: "First instruction on the test order screen"
        )
        static let instruction2 = NSLocalizedString(
            "Select your product, add to cart, and complete checkout on that web store as a real customer.",
            comment: "Second instruction on the test order screen"
        )
        static let instruction3 = NSLocalizedString(
            "Complete the payment and await a push notification about the order on your WooCommerce app.",
            comment: "Third instruction on the test order screen"
        )
        static let instruction4 = NSLocalizedString(
            "Use the app to process the refund for the order. %1$@",
            comment: "Fourth instruction on the test order screen. %1$@ is a tappable link to documentation about processing fees not being refundable."
        )
        static let feesNotRefundable = NSLocalizedString(
            "Processing fees aren't refundable",
            comment: "Tappable link on the fourth instruction of the test order screen that opens documentation about processing fees not being refundable."
        )
        static let startAction = NSLocalizedString("Place order", comment: "Title on the action button on the test order screen")
    }
}

struct CreateTestOrderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTestOrderView {}
    }
}
