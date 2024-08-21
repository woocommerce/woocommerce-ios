import SwiftUI

struct PointOfSaleCardPresentPaymentSuccessMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Constants.headerSpacing) {
            successIcon
            VStack(alignment: .center, spacing: Constants.textSpacing) {
                Text(viewModel.title)
                    .font(.posTitleEmphasized)
                    .foregroundStyle(Color.posPrimaryTexti3)
                    .accessibilityAddTraits(.isHeader)

                if let message = viewModel.message {
                    Text(message)
                        .font(.posBodyRegular)
                        .foregroundStyle(Color.posPrimaryTexti3)
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
                .foregroundColor(Color(uiColor: .systemBackground))
            Image(systemName: Constants.imageName)
                .font(.system(size: Constants.checkmarkSize, weight: .bold))
                .foregroundColor(Color(.wooCommerceEmerald(.shade40)))
                .accessibilityHidden(true)
        }
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
    PointOfSaleCardPresentPaymentSuccessMessageView(
        viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel(formattedOrderTotal: "$3.00")
    )
}
