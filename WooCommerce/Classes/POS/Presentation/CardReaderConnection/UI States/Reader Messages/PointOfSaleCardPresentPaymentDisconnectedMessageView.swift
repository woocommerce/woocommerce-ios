import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.errorElementSpacing) {
            POSErrorExclamationMark()

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.instruction)
                    .font(.posBodyRegular)
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
