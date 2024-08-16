import SwiftUI

struct SimpleProductsOnlyInformation: View {
    @Binding var isPresented: Bool
    let deepLinkNavigator: DeepLinkNavigator?

    init(isPresented: Binding<Bool>,
         deepLinkNavigator: DeepLinkNavigator? = AppDelegate.shared.tabBarController) {
        self._isPresented = isPresented
        self.deepLinkNavigator = deepLinkNavigator
    }

    var body: some View {
        VStack(spacing: Constants.contentBlockSpacing) {
            VStack(spacing: Constants.textSpacing) {
                Text(Localization.modalTitle)
                    .font(.posTitleEmphasized)

                Group {
                    Text(Localization.simpleProductsOnlyIssueMessage)
                    Text(Localization.simpleProductsOnlyFutureMessage)
                }
                .font(.posBodyRegular)

                VStack(spacing: Constants.textSpacing) {
                    Text(Localization.modalHint)
                        .font(.posDetailLight)

                    Button {
                        deepLinkNavigator?.navigate(to: OrdersDestination.createOrder)
                    } label: {
                        Label(Localization.modalAction, systemImage: "plus")
                            .font(.posDetailLight)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.hintVerticalPadding)
                .padding(.horizontal, Constants.hintHorizontalPadding)
                .background(Color(.quaternarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: Constants.hintBackgroundCornerRadius))
            }
            .multilineTextAlignment(.center)

            Button(action: {
                isPresented = false
            }) {
                Text(Localization.okButtonTitle)
            }
            .buttonStyle(POSSecondaryButtonStyle())
        }
        .padding(Constants.modalContentPadding)
        .frame(width: Constants.modalFrameWidth)
    }
}

// Constants and Localization enums
private extension SimpleProductsOnlyInformation {
    enum Constants {
        static let modalFrameWidth: CGFloat = 896
        static let modalContentPadding: CGFloat = 40
        static let hintVerticalPadding: CGFloat = 24
        static let hintHorizontalPadding: CGFloat = 40
        static let hintBackgroundCornerRadius: CGFloat = 8
        static let contentBlockSpacing: CGFloat = 40
        static let textSpacing: CGFloat = 16
    }

    enum Localization {
        static let modalTitle = NSLocalizedString(
            "pos.simpleProductsModal.title",
            value: "Why can't I see my products?",
            comment: "Title of the simple products information modal in POS"
        )
        static let simpleProductsOnlyIssueMessage = NSLocalizedString(
            "pos.simpleProductsModal.message.issue",
            value: "Only simple physical products can be used with POS right now.",
            comment: "Message in the simple products information modal in POS"
        )
        static let simpleProductsOnlyFutureMessage = NSLocalizedString(
            "pos.simpleProductsModal.message.future",
            value: "Other product types, such as variable and virtual, will be available in future updates.",
            comment: "Message in the simple products information modal in POS, explaining future plans"
        )
        static let modalHint = NSLocalizedString(
            "pos.simpleProductsModal.hint",
            value: "To take payment for a non-simple product, exit POS and create a new order from the orders tab.",
            comment: "Hint in the simple products information modal in POS"
        )
        static let modalAction = NSLocalizedString(
            "pos.simpleProductsModal.action",
            value: "Create an order in store management",
            comment: "Action text in the simple products information modal in POS"
        )
        static let okButtonTitle = NSLocalizedString(
            "pos.simpleProductsModal.ok.button.title",
            value: "OK",
            comment: "Title for the OK button on the simple products information modal in POS"
        )
    }
}

#Preview {
    SimpleProductsOnlyInformation(isPresented: .constant(true),
                                  deepLinkNavigator: nil)
}
