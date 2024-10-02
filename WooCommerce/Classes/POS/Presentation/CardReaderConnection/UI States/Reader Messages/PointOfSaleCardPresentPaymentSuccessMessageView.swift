import SwiftUI

struct PointOfSaleCardPresentPaymentSuccessMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: Constants.headerSpacing) {
            successIcon
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
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

    private var successIcon: some View {
        ZStack {
            Circle()
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                .shadow(color: Color(.wooCommerceEmerald(.shade80)).opacity(Constants.shadowOpacity),
                        radius: Constants.shadowRadius, x: Constants.shadowSize.width, y: Constants.shadowSize.height)
                .foregroundColor(circleBackgroundColor)
            Image(PointOfSaleAssets.successCheck.imageName)
                .renderingMode(.template)
                .foregroundColor(checkmarkColor)
                .frame(width: 52)
                .accessibilityHidden(true)
        }
    }

    private var circleBackgroundColor: Color {
        Color(red: 8/255, green: 251/255, blue: 135/255)
    }

    private var checkmarkColor: Color {
        Color.posSecondaryBackground
    }
}

private extension PointOfSaleCardPresentPaymentSuccessMessageView {
    enum Constants {
        static let imageName: String = "checkmark"
        static let imageSize: CGSize = .init(width: 165, height: 165)
        static let checkmarkSize: CGFloat = 56
        static let shadowOpacity: CGFloat = 0.16
        static let shadowRadius: CGFloat = 16
        static let shadowSize: CGSize = .init(width: 0, height: 8)
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
