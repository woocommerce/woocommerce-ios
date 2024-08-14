import SwiftUI

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
            Text(viewModel.title)
                .font(.posTitleEmphasized)
                .foregroundStyle(Color.posPrimaryTexti3)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentCancelledOnReaderMessageView(
        viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel()
    )
}
