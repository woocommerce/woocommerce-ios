import SwiftUI
import PointOfSale

@available(iOS 17.0, *)
struct SimpleProductsOnlyInformation: View {
    @Binding var isPresented: Bool
    @Environment(\.posNavigation) private var navigation

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        PointOfSaleInformationModal(isPresented: $isPresented, title: AttributedString(Localization.modalTitle)) {
            PointOfSaleInformationModalParagraphView {
                Text(issueMessage)
                Text(futureMessage)
            }

            PointOfSaleInformationModalParagraphView(style: .outlined) {
                Text(hintMessage)

                Spacer().frame(height: POSSpacing.small)

                Button {
                    navigation.navigateToCreateOrder()
                } label: {
                    Label(Localization.modalAction, systemImage: "plus")
                        .font(.posBodySmallRegular())
                }
                .foregroundStyle(Color.posPrimary)
            }
        }
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
    SimpleProductsOnlyInformation(isPresented: .constant(true))
}
