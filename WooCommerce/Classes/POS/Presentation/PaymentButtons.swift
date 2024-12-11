import SwiftUI

struct PaymentsActionButtons: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @State private var isShowingSendReceiptModal: Bool = false
    @State private var sendReceiptError: Bool = false
    @Binding private(set) var isShowingReceiptNotEligibleBanner: Bool

    private var shouldShowSendReceiptButton: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sendReceiptsForPointOfSale)
    }

    var body: some View {
        ZStack {
            VStack {
                sendReceiptButton
                    .renderedIf(shouldShowSendReceiptButton)
                newOrderButton
            }
            .sheet(isPresented: $sendReceiptError) {
                // Temporary:
                HStack {
                    Text("Error")
                    Text("Error sending receipt")
                }
            }
            .posModal(isPresented: $isShowingSendReceiptModal) {
                POSSendReceiptModalView(sendReceipt: { email in
                    Task { @MainActor in
                        do {
                            try await posModel.sendReceipt(to: email)
                            sendReceiptError = false
                        } catch {
                            sendReceiptError = true
                        }
                    }
                }, isPresented: $isShowingSendReceiptModal)
                .posModalSizing()
            }
        }
    }
}

private extension PaymentsActionButtons {
    var sendReceiptButton: some View {
        Button(action: {
            if posModel.eligibleWooCommerceVersionForPOSReceipts {
                isShowingSendReceiptModal = true
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
        .background(Color.posOverlayFillInverted)
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
    PaymentsActionButtons(isShowingReceiptNotEligibleBanner: .constant(true))
        .environmentObject(posModel)
}
#endif
