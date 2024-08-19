import SwiftUI

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
            Image(viewModel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                       height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .font(.posBodyRegular)

                Text(viewModel.message)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(
        viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
            inputMethods: [.tap, .insert]
        ))
}
