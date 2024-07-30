import SwiftUI

struct PointOfSaleCardPresentPaymentValidatingOrderMessageView: View {
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    init(viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel) {
        self.title = viewModel.title
        self.message = viewModel.message
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                    .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                           height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(title)
                        .foregroundStyle(Color(.neutral(.shade40)))
                        .font(.posBody)

                    Text(message)
                        .font(.posTitle)
                        .foregroundStyle(Color(.neutral(.shade60)))
                        .bold()
                }
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentValidatingOrderMessageView(
        viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel())
}
