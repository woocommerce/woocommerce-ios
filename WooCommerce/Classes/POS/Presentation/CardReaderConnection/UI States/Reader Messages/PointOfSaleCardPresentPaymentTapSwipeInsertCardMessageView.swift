import SwiftUI

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
                Image(viewModel.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                           height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
                VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                    Text(viewModel.title)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .font(.posBody)

                    Text(viewModel.message)
                        .font(.posTitle)
                        .foregroundStyle(Color.posPrimaryTexti3)
                        .bold()
                }
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(
        viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
            inputMethods: [.tap, .insert]
        ))
}
