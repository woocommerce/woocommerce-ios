import SwiftUI

@available(iOS 17.0, *)
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
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
                .padding(Constants.dismissIconPadding)
                .foregroundColor(Color.posOnSurfaceVariantLowest)
            }

            VStack(spacing: Constants.textSpacing) {
                Text(Localization.modalTitle)
                    .font(.posHeadingBold)

                Group {
                    Text(issueMessage)
                    Text(futureMessage)
                }
                .font(.posBodyLargeRegular())
            }
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.center)

            VStack(spacing: Constants.textSpacing) {
                Text(hintMessage)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurface)

                Button {
                    deepLinkNavigator?.navigate(to: OrdersDestination.createOrder)
                } label: {
                    Label(Localization.modalAction, systemImage: "plus")
                        .font(.posBodySmallRegular())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.hintVerticalPadding)
            .padding(.horizontal, Constants.hintHorizontalPadding)
            .background(Color(.posSurfaceDim))
            .clipShape(RoundedRectangle(cornerRadius: Constants.hintBackgroundCornerRadius))
            .multilineTextAlignment(.center)

            Button(action: {
                isPresented = false
            }) {
                Text(Localization.okButtonTitle)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(Constants.modalContentPadding)
        .frame(width: Constants.modalFrameWidth)
    }

    private var issueMessage: String {
        Localization.variableAndSimpleProductsOnlyIssueMessage
    }

    private var futureMessage: String {
        Localization.variableAndSimpleProductsOnlyFutureMessage
    }

    private var hintMessage: String {
        Localization.variableAndSimpleProdustsOnlyHint
    }
}

// Constants and Localization enums
@available(iOS 17.0, *)
private extension SimpleProductsOnlyInformation {
    enum Constants {
        static let modalFrameWidth: CGFloat = 896
        static let modalContentPadding: CGFloat = POSSpacing.medium
        static let hintVerticalPadding: CGFloat = POSSpacing.medium
        static let hintHorizontalPadding: CGFloat = POSSpacing.medium
        static let hintBackgroundCornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
        static let contentBlockSpacing: CGFloat = POSSpacing.xxLarge
        static let textSpacing: CGFloat = POSSpacing.small
        static let dismissIconPadding: EdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
    }

    enum Localization {
        static let modalTitle = NSLocalizedString(
            "pos.simpleProductsModal.title",
            value: "Why can't I see my products?",
            comment: "Title of the simple products information modal in POS"
        )

        static let variableAndSimpleProductsOnlyIssueMessage = NSLocalizedString(
            "pos.simpleProductsModal.message.issue.variableAndSimple",
            value: "Only simple and variable non-downloadable products can be used with POS right now.",
            comment: "Message in the simple products information modal in POS when variable products are supported"
        )
        static let variableAndSimpleProductsOnlyFutureMessage = NSLocalizedString(
            "pos.simpleProductsModal.message.future.variableAndSimple",
            value: "Other product types will be available in future updates.",
            comment: "Message in the simple products information modal in POS, explaining future plans when variable products are supported"
        )
        static let variableAndSimpleProdustsOnlyHint = NSLocalizedString(
            "pos.simpleProductsModal.hint.variableAndSimple",
            value: "To take payment for an unsupported product, exit POS and create a new order from the orders tab.",
            comment: "Hint in the simple products information modal in POS, explaining future plans when variable products are supported"
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

@available(iOS 17.0, *)
#Preview {
    SimpleProductsOnlyInformation(isPresented: .constant(true),
                                  deepLinkNavigator: nil)
}
