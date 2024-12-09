import SwiftUI

struct PaymentsActionButtons: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @State private var isShowingSendReceiptModal: Bool = false

    private var shouldShowSendReceiptButton: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sendReceiptsForPointOfSale)
    }

    var body: some View {
        VStack {
            sendReceiptButton
                .renderedIf(shouldShowSendReceiptButton)
            newOrderButton
        }
        .posModal(isPresented: $isShowingSendReceiptModal) {
            POSSendReceiptModalView(sendReceipt: { email in
                Task { @MainActor in
                    await posModel.sendReceipt(to: email)
                }
            }, isPresented: $isShowingSendReceiptModal)
            .posModalSizing()
        }
    }
}

private extension PaymentsActionButtons {
    var sendReceiptButton: some View {
        Button(action: {
            isShowingSendReceiptModal = true
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.sendReceipt)
                    .font(Constants.buttonFont)
            }
            .frame(minWidth: UIScreen.main.bounds.width / 2)
        })
        .padding(Constants.buttonPadding)
        .foregroundColor(Color.posPrimaryText)
        .background(Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                        .stroke(Color.posPrimaryText, lineWidth: 1.0)
        }
    }

    var newOrderButton: some View {
        Button(action: {
            posModel.startNewCart()
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.newOrder)
                    .font(Constants.buttonFont)
            }
            .frame(minWidth: UIScreen.main.bounds.width / 2)
        })
        .padding(Constants.buttonPadding)
        .foregroundColor(Color.posPrimaryTextInverted)
        .background(Color.posOverlayFillInverted)
        .cornerRadius(Constants.buttonCornerRadius)
    }
}

extension PaymentsActionButtons {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
    }

    enum Localization {
        static let newOrder = NSLocalizedString(
            "pos.totalsView.newOrder",
            value: "New order",
            comment: "Button title for new order button")
        static let sendReceipt = NSLocalizedString(
            "pos.totalsView.sendReceipt",
            value: "Receipt",
            comment: "Button title for the receipt button")
    }
}

#if DEBUG
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    PaymentsActionButtons()
        .environmentObject(posModel)
}
#endif
