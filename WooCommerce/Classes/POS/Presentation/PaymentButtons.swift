import SwiftUI

struct PaymentsActionButtons: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @Binding var isShowingSendReceiptView: Bool
    @Binding private(set) var isShowingReceiptNotEligibleBanner: Bool

    private var shouldShowSendReceiptButton: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sendReceiptsForPointOfSale)
    }

    var body: some View {
        ZStack {
            VStack {
                newOrderButton
                sendReceiptButton
                    .renderedIf(shouldShowSendReceiptButton)
            }
        }
    }
}

private extension PaymentsActionButtons {
    var sendReceiptButton: some View {
        Button(action: {
            if posModel.eligibleWooCommerceVersionForPOSReceipts {
                isShowingSendReceiptView = true
            } else {
                isShowingReceiptNotEligibleBanner = true
            }
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
        .background(Color.posPrimaryButtonBackground)
        .cornerRadius(Constants.buttonCornerRadius)
    }
}

private extension PaymentsActionButtons {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
    }

    enum Localization {
        static let newOrder = NSLocalizedString(
            "pos.totalsView.button.newOrder",
            value: "New order",
            comment: "Button title for new order button")
        static let sendReceipt = NSLocalizedString(
            "pos.totalsView.button.sendReceipt",
            value: "Email receipt",
            comment: "Button title for the receipt button")
    }
}

#if DEBUG
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    PaymentsActionButtons(isShowingSendReceiptView: .constant(false), isShowingReceiptNotEligibleBanner: .constant(true))
        .environmentObject(posModel)
}
#endif
