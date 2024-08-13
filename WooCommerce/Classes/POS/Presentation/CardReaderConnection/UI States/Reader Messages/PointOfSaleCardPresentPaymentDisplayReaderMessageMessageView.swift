import SwiftUI
import Lottie

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.headerSpacing) {
            LottieView(animation: .named("card-animation"))
                .playing(loopMode: .loop)
                .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                       height: PointOfSaleCardPresentPaymentLayout.headerSize.height)

            VStack(alignment: .center, spacing: Layout.textSpacing) {
                Text(viewModel.title)
                    .foregroundStyle(.white)
                    .font(.posBody)

                Text(viewModel.message)
                    .font(.posTitle)
                    .foregroundStyle(.white)
            }
        }
        .padding(.bottom)
        .multilineTextAlignment(.center)
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
