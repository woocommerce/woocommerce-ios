import SwiftUI

struct PaymentsActionButtons: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Binding var isShowingSendReceiptView: Bool
    @Binding private(set) var isShowingReceiptNotEligibleBanner: Bool

    private let receiptEligibilityUseCase = ReceiptEligibilityUseCase()

    var body: some View {
        ZStack {
            VStack {
                newOrderButton
                sendReceiptButton
            }
        }
    }
}

private extension PaymentsActionButtons {
    var sendReceiptButton: some View {
        Button(action: {
            Task { @MainActor in
                ServiceLocator.analytics.track(.receiptEmailTapped)
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

private extension PaymentsActionButtons {
    enum Constants {
        static let buttonSpacing: CGFloat = POSSpacing.medium
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
    PaymentsActionButtons(isShowingSendReceiptView: .constant(false), isShowingReceiptNotEligibleBanner: .constant(true))
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
