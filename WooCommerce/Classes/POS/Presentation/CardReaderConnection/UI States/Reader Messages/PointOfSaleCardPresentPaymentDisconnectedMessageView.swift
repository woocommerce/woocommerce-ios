import SwiftUI

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(viewModel.title)
                        .font(.posTitle)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .bold()
                }

                HStack {
                    Button(viewModel.collectPaymentButtonViewModel.title, action: viewModel.collectPaymentButtonViewModel.actionHandler)
                }
                .padding()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(
        viewModel: PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel(
            collectPaymentAction: {})
    )
}
