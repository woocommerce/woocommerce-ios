import SwiftUI

@available(iOS 17.0, *)
struct PaymentsActionButtons: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Binding var isShowingSendReceiptView: Bool
    @Binding private(set) var isShowingReceiptNotEligibleBanner: Bool

    private let receiptEligibilityUseCase = ReceiptEligibilityUseCase()

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

@available(iOS 17.0, *)
private extension PaymentsActionButtons {
    var sendReceiptButton: some View {
        Button(action: {
            Task { @MainActor in
                ServiceLocator.analytics.track(.pointOfSaleEmailReceiptTapped)
                await handleSendReceiptAction()
            }
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.sendReceipt)
            }
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }

    var newOrderButton: some View {
        Button(action: {
            ServiceLocator.analytics.track(.pointOfSaleCreateNewOrderTapped)
            posModel.startNewCart()
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.newOrder)
            }
        })
        .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}

@available(iOS 17.0, *)
private extension PaymentsActionButtons {
    func handleSendReceiptAction() async {
        let isEligible = await checkReceiptEligibility()
        if isEligible {
            isShowingSendReceiptView = true
        } else {
            isShowingReceiptNotEligibleBanner = true
        }
    }

    func checkReceiptEligibility() async -> Bool {
        await withCheckedContinuation { continuation in
            receiptEligibilityUseCase.isEligibleForPointOfSaleReceipts { isEligible in
                continuation.resume(returning: isEligible)
            }
        }
    }
}

@available(iOS 17.0, *)
private extension PaymentsActionButtons {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
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
@available(iOS 17.0, *)
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    PaymentsActionButtons(isShowingSendReceiptView: .constant(false), isShowingReceiptNotEligibleBanner: .constant(true))
        .environment(posModel)
}
#endif
