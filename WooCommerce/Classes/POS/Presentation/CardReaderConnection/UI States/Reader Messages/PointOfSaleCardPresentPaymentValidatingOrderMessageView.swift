import SwiftUI

struct PointOfSaleCardPresentPaymentValidatingOrderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                    .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                           height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(Color(.neutral(.shade40)))
                        .font(.posBody)

                    Text(viewModel.message)
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
