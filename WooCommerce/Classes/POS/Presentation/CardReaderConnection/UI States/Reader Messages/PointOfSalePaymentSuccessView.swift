import SwiftUI

@available(iOS 17.0, *)
struct PointOfSalePaymentSuccessView: View {
    let viewModel: PointOfSalePaymentSuccessViewModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(PointOfSaleAggregateModel.self) private var posModel

    @State private var isShowingSendReceiptView: Bool = false
    @State private var isShowingReceiptNotEligibleBanner: Bool = false
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack {
            if isShowingSendReceiptView {
                POSSendReceiptView(isShowingSendReceiptView: $isShowingSendReceiptView)
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

                successIcon
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

                PaymentsActionButtons(isShowingSendReceiptView: $isShowingSendReceiptView,
                                      isShowingReceiptNotEligibleBanner: $isShowingReceiptNotEligibleBanner)
                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: POSSpacing.none)
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
                .opacity(isViewLoaded ? 1 : 0)

                Spacer()
            }
            .multilineTextAlignment(.center)

            if isShowingReceiptNotEligibleBanner {
                VStack {
                    Spacer()
                    POSReceiptEligibilityBanner(isVisible: $isShowingReceiptNotEligibleBanner)
                        .transition(.move(edge: .bottom))
                        .padding(.bottom)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                .foregroundColor(.posSuccess)
            Image(PointOfSaleAssets.successCheck.imageName)
                .renderingMode(.template)
                .foregroundColor(checkmarkColor)
                .frame(width: Constants.checkmarkSize)
                .accessibilityHidden(true)
        }
    }

    private var checkmarkColor: Color {
        .posOnSuccess
    }
}

@available(iOS 17.0, *)
private extension PointOfSalePaymentSuccessView {
    enum Constants {
        static let imageName: String = "checkmark"
        static let imageSize: CGSize = .init(width: 165, height: 165)
        static let checkmarkSize: CGFloat = 52
        static let shadowOpacity: CGFloat = 0.16
        static let shadowRadius: CGFloat = 16
        static let shadowSize: CGSize = .init(width: 0, height: 8)
        static let textSpacing: CGFloat = POSSpacing.small
        static let animationOffset: CGFloat = 100
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    PointOfSalePaymentSuccessView(
        viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$3.00",
                                                      paymentMethod: .card)
    )
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
