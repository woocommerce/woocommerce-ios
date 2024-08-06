import SwiftUI

struct PointOfSaleCardPresentPaymentSuccessMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel

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
    PointOfSaleCardPresentPaymentSuccessMessageView(
        viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel()
    )
}
