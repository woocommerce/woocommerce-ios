import SwiftUI

struct PointOfSaleCardPresentPaymentDisconnectedMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisconnectedMessageViewModel

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
                    Button(viewModel.collectPaymentViewModel.title, action: viewModel.collectPaymentViewModel.actionHandler)
                }
                .padding()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentDisconnectedMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisconnectedMessageViewModel(
            collectPaymentAction: {})
    )
}
