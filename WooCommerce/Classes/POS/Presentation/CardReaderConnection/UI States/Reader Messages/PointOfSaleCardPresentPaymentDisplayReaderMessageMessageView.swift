import SwiftUI

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
                Rectangle()
                    .foregroundStyle(Color(.wooCommercePurple(.shade20)))
                    .cornerRadius(13)
                    .frame(width: Layout.headerSize.width, height: Layout.headerSize.height)

                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(.white)
                        .font(.posBody)

                    Text(viewModel.message)
                        .font(.posTitle)
                        .foregroundStyle(.white)
                        .bold()
                }
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(
            message: "Remove card"))
}

private extension PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView {
    enum Layout {
        static let headerSize: CGSize = .init(width: 130, height: 114.4)
        static let cornerRadius: CGFloat = 13
    }
}
