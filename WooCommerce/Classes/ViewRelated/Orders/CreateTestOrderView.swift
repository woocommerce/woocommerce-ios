import SwiftUI

/// View with instructions to create a test order.
struct CreateTestOrderView: View {
    private let instructions: [String] = [
        Localization.instruction1,
        Localization.instruction2,
        Localization.instruction3,
        Localization.instruction4
    ]

    var body: some View {
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
                        Text("\(index)")
                            .bodyStyle()
                            .background(
                                Circle()
                                    .padding(8)
                                    .foregroundColor(.init(uiColor: .listBackground))
                            )

                        Text(content)
                            .subheadlineStyle()
                    }
                }
                .padding(.horizontal, Layout.instructionMargin)
            }

            /// CTA
            Button(Localization.startAction) {
                // TODO
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.buttonMargin)
        }
    }
}

private extension CreateTestOrderView {
    enum Layout {
        static let instructionMargin: CGFloat = 24
        static let instructionSpacing: CGFloat = 16
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
        CreateTestOrderView()
    }
}
