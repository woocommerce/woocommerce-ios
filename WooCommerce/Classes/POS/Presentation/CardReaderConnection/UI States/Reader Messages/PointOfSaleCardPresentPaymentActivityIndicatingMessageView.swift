import SwiftUI

struct PointOfSaleCardPresentPaymentActivityIndicatingMessageView: View {
    let title: String
    let message: String
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.headerSpacing) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                       height: PointOfSaleCardPresentPaymentLayout.headerSize.height)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.smallTextSpacing) {
                Text(title)
                    .foregroundStyle(Color(.neutral(.shade40)))
                    .font(.posBodyRegular)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(message)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color(.neutral(.shade60)))
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentActivityIndicatingMessageView(
        title: "Checking order",
        message: "Getting ready",
        animation: .init(namespace: namespace)
    )
}
