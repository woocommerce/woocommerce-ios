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
                    .bold()
                Text(viewModel.instruction)
                    .font(.posBody)
                    .foregroundStyle(Color.posPrimaryTexti3)
            }

            Button(action: viewModel.collectPaymentButtonViewModel.actionHandler) {
                Text(viewModel.collectPaymentButtonViewModel.title)
            }
            .buttonStyle(POSPrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(
        viewModel: PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel(
            collectPaymentAction: {})
    )
}
