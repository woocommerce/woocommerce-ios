import SwiftUI

struct PointOfSaleCardPresentPaymentSuccessMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation

    var body: some View {
        VStack(alignment: .center, spacing: Constants.headerSpacing) {
            VStack(alignment: .center, spacing: Constants.textSpacing) {
                Text(viewModel.title)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                if let message = viewModel.message {
                    Text(message)
                        .font(.posBodyRegular)
                        .foregroundStyle(Color.posPrimaryText)
                        .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
                }
            }
        }
        .multilineTextAlignment(.center)
    }
}

private extension PointOfSaleCardPresentPaymentSuccessMessageView {
    enum Constants {
        static let headerSpacing: CGFloat = 56
        static let textSpacing: CGFloat = 16
    }
}

#Preview {
    @Namespace var namespace

    return PointOfSaleCardPresentPaymentSuccessMessageView(
        viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel(formattedOrderTotal: "$3.00"),
        animation: .init(namespace: namespace)
    )
}
