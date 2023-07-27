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
                            Text(content)
                                .font(.subheadline)
                                .foregroundColor(.init(uiColor: .text))
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

private extension CreateTestOrderView {
    enum Layout {
        static let instructionMargin: CGFloat = 24
        static let instructionSpacing: CGFloat = 16
        static let instructionIndexPadding: CGFloat = 12
        static let buttonMargin: CGFloat = 16
        static let blockSpacing: CGFloat = 32
    }
    enum Localization {
        static let title = NSLocalizedString("Try a test order", comment: "Title shown on the test order screen")
        static let instruction1 = NSLocalizedString(
            "Tap the button below to be redirected to your online store via a web browser.",
            comment: "First instruction on the test order screen"
        )
        static let instruction2 = NSLocalizedString(
            "Select your test product, add to cart, and complete checkout on that web store as a real customer.",
            comment: "Second instruction on the test order screen"
        )
        static let instruction3 = NSLocalizedString(
            "Complete the payment and await a push notification about the order on your WooCommerce app.",
            comment: "Third instruction on the test order screen"
        )
        static let instruction4 = NSLocalizedString(
            "Use the app to process the refund for the test order.",
            comment: "Fourth instruction on the test order screen"
        )
        static let startAction = NSLocalizedString("Start Test order", comment: "Title on the action button on the test order screen")
    }
}

struct CreateTestOrderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTestOrderView {}
    }
}
