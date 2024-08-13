import SwiftUI

struct PointOfSaleCardPresentPaymentActivityIndicatingMessageView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                       height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                Text(title)
                    .foregroundStyle(Color(.neutral(.shade40)))
                    .font(.posBody)

                Text(message)
                    .font(.posTitle)
                    .foregroundStyle(Color(.neutral(.shade60)))
            }
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: "Checking order", message: "Getting ready")
}
