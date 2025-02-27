import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    private let connectCardReader: () -> Void

    @State private var width: CGFloat = 0

    init(connectCardReader: @escaping () -> Void) {
        self.connectCardReader = connectCardReader
    }

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            Image(decorative: PointOfSaleAssets.readerDisconnected.imageName)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
            }
            .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)

            Spacer()
                .frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

            Button {
                connectCardReader()
            } label: {
                Text(viewModel.connectReaderButtonTitle)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(width: width * 0.5)
        }
        .measureWidth({ containerWidth in
            width = containerWidth
        })
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(connectCardReader: {})
}
#endif
