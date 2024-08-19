import SwiftUI

struct PointOfSaleCardPresentPaymentProcessingMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.headerSpacing) {
            Image(viewModel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                       height: PointOfSaleCardPresentPaymentLayout.headerSize.height)

            VStack(alignment: .center, spacing: Layout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(.white)
                    .font(.posBodyRegular)

                Text(viewModel.message)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posQuaternaryTextInverted)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .padding(.bottom)
        .multilineTextAlignment(.center)
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
