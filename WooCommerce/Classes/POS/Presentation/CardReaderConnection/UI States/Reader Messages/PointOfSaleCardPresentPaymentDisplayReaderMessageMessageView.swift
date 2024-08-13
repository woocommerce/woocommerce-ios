import SwiftUI

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: Layout.headerSpacing) {
                SVGAnimationView(svgName: "card-animation")
                    .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                           height: PointOfSaleCardPresentPaymentLayout.headerSize.height)

                VStack(alignment: .center, spacing: Layout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(.white)
                        .font(.posBody)

                    Text(viewModel.message)
                        .font(.posTitle)
                        .foregroundStyle(.white)
                        .bold()
                }
            }
            .padding(.bottom)
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView {
    enum Layout {
        static let headerSpacing: CGFloat = 48
        static let textSpacing: CGFloat = 16
    }
}

#Preview {
    PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(
            message: "Remove card"))
}
