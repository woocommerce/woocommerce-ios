import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    private let connectCardReader: () -> Void

    init(connectCardReader: @escaping () -> Void) {
        self.connectCardReader = connectCardReader
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
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

            GeometryReader { geometry in
                Button {
                    connectCardReader()
                } label: {
                    Text(viewModel.connectReaderButtonTitle)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .frame(width: geometry.size.width * 0.5)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(connectCardReader: {})
}
#endif
