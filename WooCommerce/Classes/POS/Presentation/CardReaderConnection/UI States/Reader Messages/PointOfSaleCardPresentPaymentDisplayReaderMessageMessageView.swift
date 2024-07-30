import SwiftUI

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(viewModel.message)
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
    PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(
            message: "Please remove card"))
}
