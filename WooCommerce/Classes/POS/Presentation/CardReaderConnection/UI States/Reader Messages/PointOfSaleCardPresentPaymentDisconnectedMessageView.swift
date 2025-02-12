import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel()
    private let connectCardReader: () -> Void

    init(connectCardReader: @escaping () -> Void) {
        self.connectCardReader = connectCardReader
    }

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posHeading)
                    .foregroundStyle(Color.posPrimaryText)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posPrimaryText)
            }

            Button {
                connectCardReader()
            } label: {
                Text(viewModel.connectReaderButtonTitle)
            }
            .buttonStyle(POSButtonStyle(variant: .filled, size: .normal))
        }
        .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(connectCardReader: {})
}
#endif
