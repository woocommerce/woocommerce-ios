import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    private let connectCardReader: () -> Void
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posLayoutScale) private var layoutScale

    @State private var width: CGFloat = 0

    init(connectCardReader: @escaping () -> Void) {
        self.connectCardReader = connectCardReader
    }

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            POSCardPresentPaymentMessageViewImage(imageName: PointOfSaleAssets.readerDisconnected.imageName)

            Spacer()
                .frame(height: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing))

            VStack(alignment: .center, spacing: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.textSpacing)) {
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
                .frame(height: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing))

            Button {
                connectCardReader()
            } label: {
                Text(viewModel.connectReaderButtonTitle)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .if(layoutScale == .tablet) { $0.frame(width: width * 0.5) }
            .if(layoutScale == .phone) { $0.frame(maxWidth: .infinity).padding(.horizontal, POSPadding.medium) }
        }
        .frame(maxWidth: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
        .multilineTextAlignment(.center)
    }

    private func dynamicSpacing(_ spacing: CGFloat) -> CGFloat {
        guard scale > 1 else {
            return spacing
        }

        return spacing * (1 / scale)
    }
}

#if DEBUG
#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(connectCardReader: {})
}
#endif
