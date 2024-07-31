import SwiftUI

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.title)
                    .font(.posTitle)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .bold()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(
        viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel()
    )
}
