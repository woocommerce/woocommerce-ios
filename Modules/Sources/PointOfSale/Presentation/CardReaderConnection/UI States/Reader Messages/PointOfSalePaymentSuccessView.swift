import SwiftUI

struct PointOfSalePaymentSuccessView: View {
    let viewModel: PointOfSalePaymentSuccessViewModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(PointOfSaleAggregateModel.self) private var posModel

    @State private var isShowingSendReceiptView: Bool = false
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack {
            if isShowingSendReceiptView {
                POSSendReceiptView(isShowingSendReceiptView: $isShowingSendReceiptView) { email in
                    try await posModel.sendReceipt(to: email)
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
                .barcodeScanning { barcode in
                    posModel.startNewCart()
                    posModel.barcodeScanned(barcode)
                }
            }
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

                Spacer().frame(height: POSSpacing.xxLarge)

                PaymentsActionButtons(isShowingSendReceiptView: $isShowingSendReceiptView)
                    .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: POSSpacing.none)
                    .frame(maxWidth: .infinity, alignment: .center)
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
}

#if DEBUG
#Preview {
    PointOfSalePaymentSuccessView(
        viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$3.00",
                                                      paymentMethod: .card)
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
