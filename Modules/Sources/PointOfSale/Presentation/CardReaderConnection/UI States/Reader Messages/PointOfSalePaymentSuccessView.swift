import SwiftUI

struct PointOfSalePaymentSuccessView: View {
    let viewModel: PointOfSalePaymentSuccessViewModel
    let customerEmail: String?
    let onSendReceipt: (String) async throws -> Void
    let successAction: PaymentFlowAction
    let onSuccessScreenBarcodeScanned: ((Result<String, HIDBarcodeParserError>) -> Void)?
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.posLayoutScale) private var layoutScale

    @State private var isShowingSendReceiptView: Bool = false
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack {
            if isShowingSendReceiptView {
                POSSendReceiptView(isShowingSendReceiptView: $isShowingSendReceiptView) { email in
                    try await onSendReceipt(email)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                HStack(alignment: .center) {
                    Spacer()
                    successView
                    Spacer()
                }
                .padding([.leading, .trailing], dynamicTypeSize.isAccessibilitySize ? nil : POSPadding.small)
                .background(Color.posSurfaceBright)
            }
        }
        .barcodeScanning(enabled: .constant(onSuccessScreenBarcodeScanned != nil && !isShowingSendReceiptView)) { barcode in
            onSuccessScreenBarcodeScanned?(barcode)
        }
        .accessibilityIdentifier("pos-payment-success-view")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isViewLoaded = true
            }
        }
        .animation(.default, value: isShowingSendReceiptView)
    }

    private var successView: some View {
        ZStack {
            VStack(alignment: .center, spacing: POSSpacing.none) {
                Spacer()

                POSSuccessIcon()
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                    .scaleEffect(isViewLoaded ? 1 : 0)
                    .opacity(isViewLoaded ? 1 : 0)

                Spacer().frame(height: POSSpacing.xLarge)

                VStack(alignment: .center, spacing: Constants.textSpacing) {
                    Text(viewModel.title)
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurface)
                        .accessibilityAddTraits(.isHeader)
                        .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                        .opacity(isViewLoaded ? 1 : 0)

                    if let message = viewModel.message {
                        Text(message)
                            .font(.posBodyLargeRegular())
                            .foregroundStyle(Color.posOnSurface)
                            .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                            .opacity(isViewLoaded ? 1 : 0)
                    }
                }

                if let customerEmail, customerEmail.isNotEmpty {
                    Spacer().frame(height: Constants.textSpacing)

                    Text(String(format: Localization.receiptSentFormat, customerEmail))
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurface)
                        .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                        .opacity(isViewLoaded ? 1 : 0)
                }

                Spacer().frame(height: POSSpacing.xxLarge)

                PaymentsActionButtons(successAction: successAction,
                                      isShowingSendReceiptView: $isShowingSendReceiptView)
                    .if(layoutScale == .tablet) {
                        $0.containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: POSSpacing.none)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .if(layoutScale == .phone) {
                        $0.frame(maxWidth: .infinity)
                            .padding(.horizontal, POSPadding.medium)
                    }
                    .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)

                Spacer()
            }
            .multilineTextAlignment(.center)

        }
    }

}

private extension PointOfSalePaymentSuccessView {
    enum Constants {
        static let textSpacing: CGFloat = POSSpacing.small
        static let animationOffset: CGFloat = 100
    }

    enum Localization {
        static let receiptSentFormat = NSLocalizedString(
            "pointOfSale.paymentSuccessful.receiptSent",
            value: "A receipt has been sent to %1$@.",
            comment: "Informational message shown on payment success screen when an email receipt is automatically sent. " +
            "%1$@ is a placeholder for the customer's email address."
        )
    }
}

#if DEBUG
#Preview {
    PointOfSalePaymentSuccessView(
        viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$3.00",
                                                      paymentMethod: .card),
        customerEmail: "test@example.com",
        onSendReceipt: { _ in },
        successAction: PaymentFlowAction(title: "New order", action: {}, analyticsEvent: nil),
        onSuccessScreenBarcodeScanned: nil
    )
}
#endif
