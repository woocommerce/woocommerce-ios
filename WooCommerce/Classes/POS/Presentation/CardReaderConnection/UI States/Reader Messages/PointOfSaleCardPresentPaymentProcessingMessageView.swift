import SwiftUI

struct PointOfSaleCardPresentPaymentProcessingMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: Layout.headerSpacing) {
                Image(viewModel.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                           height: PointOfSaleCardPresentPaymentLayout.headerSize.height)

                VStack(alignment: .center, spacing: Layout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(.white)
                        .font(.posBody)

                    Text(viewModel.message)
                        .font(.posTitle)
                        .foregroundStyle(Color.posQuaternaryText)
                        .bold()
                }
            }
            .padding(.bottom)
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private extension PointOfSaleCardPresentPaymentProcessingMessageView {
    enum Layout {
        static let headerSpacing: CGFloat = 48
        static let textSpacing: CGFloat = 16
    }
}

#Preview {
    PointOfSaleCardPresentPaymentProcessingMessageView(
        viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()
    )
}
