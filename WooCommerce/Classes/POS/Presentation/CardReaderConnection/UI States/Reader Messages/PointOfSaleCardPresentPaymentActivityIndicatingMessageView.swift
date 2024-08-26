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
                    .font(.posBodyRegular)

                Text(message)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color(.neutral(.shade60)))
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentActivityIndicatingMessageView(title: "Checking order", message: "Getting ready")
}
