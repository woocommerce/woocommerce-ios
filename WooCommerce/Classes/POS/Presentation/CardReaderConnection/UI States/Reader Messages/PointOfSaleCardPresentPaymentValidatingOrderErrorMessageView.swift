import SwiftUI
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: Constants.headerSpacing) {
                POSErrorExclamationMark()
                VStack(alignment: .center, spacing: Constants.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .font(.posTitle)
                        .bold()

                    Text(viewModel.message)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .font(.posBody)
                        .padding([.leading, .trailing])
                }

                Button(viewModel.tryAgainButtonViewModel.title, action: viewModel.tryAgainButtonViewModel.actionHandler)
                    .buttonStyle(POSPrimaryButtonStyle())
                    .padding([.leading, .trailing, .bottom], Constants.buttonPadding)
                .padding()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView {
    enum Constants {
        static let headerSpacing: CGFloat = 24
        static let textSpacing: CGFloat = 16
        static let buttonPadding: CGFloat = 40
    }
}

#Preview {
    PointOfSaleCardPresentPaymentValidatingOrderErrorMessageView(
        viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel(
            error: CardReaderServiceError.paymentCapture(
                underlyingError: .paymentDeclinedByCardReader),
            tryAgainButtonAction: {}))
}
