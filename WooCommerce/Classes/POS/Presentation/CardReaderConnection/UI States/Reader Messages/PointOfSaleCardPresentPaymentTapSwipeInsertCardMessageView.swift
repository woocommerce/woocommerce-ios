import SwiftUI
import Lottie

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
            LottieView(animation: .named("card-animation"))
                .playing(loopMode: .loop)
                .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                       height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .font(.posBody)

                Text(viewModel.message)
                    .font(.posTitle)
                    .foregroundStyle(Color.posPrimaryTexti3)
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
