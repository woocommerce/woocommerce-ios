import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posTitle)
                    .foregroundStyle(Color.posPrimaryTexti3)
                Text(viewModel.instruction)
                    .font(.posBody)
                    .foregroundStyle(Color.posPrimaryTexti3)
            }

            Button(action: viewModel.connectReaderButtonViewModel.actionHandler) {
                Text(viewModel.connectReaderButtonViewModel.title)
            }
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(
        viewModel: PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel(
            connectReaderAction: {})
    )
}
