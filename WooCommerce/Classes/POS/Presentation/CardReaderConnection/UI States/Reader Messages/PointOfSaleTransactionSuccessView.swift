import SwiftUI

struct PointOfSaleTransactionSuccessView: View {
    let viewModel: PointOfSaleTransactionSuccessViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State private var isShowingSendReceiptView: Bool = false
    @State private var isShowingReceiptNotEligibleBanner: Bool = false
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack {
            if isShowingSendReceiptView {
                POSSendReceiptView(isShowingSendReceiptView: $isShowingSendReceiptView)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                ZStack {
                    VStack(alignment: .center, spacing: Constants.headerSpacing) {
                        successIcon
                            .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                            .scaleEffect(isViewLoaded ? 1 : 0)
                            .opacity(isViewLoaded ? 1 : 0)

                        VStack(alignment: .center, spacing: Constants.textSpacing) {
                            Text(viewModel.title)
                                .font(.posTitleEmphasized)
                                .foregroundStyle(Color.posPrimaryText)
                                .accessibilityAddTraits(.isHeader)
                                .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                                .opacity(isViewLoaded ? 1 : 0)

                            if let message = viewModel.message {
                                Text(message)
                                    .font(.posBodyRegular)
                                    .foregroundStyle(Color.posPrimaryText)
                                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                                    .opacity(isViewLoaded ? 1 : 0)
                            }
                        }

                        PaymentsActionButtons(isShowingSendReceiptView: $isShowingSendReceiptView,
                                           isShowingReceiptNotEligibleBanner: $isShowingReceiptNotEligibleBanner)
                            .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
                            .opacity(isViewLoaded ? 1 : 0)
                    }
                    .multilineTextAlignment(.center)

                    if isShowingReceiptNotEligibleBanner {
                        VStack {
                            Spacer()
                            POSReceiptEligibilityBanner(isVisible: $isShowingReceiptNotEligibleBanner)
                                .transition(.move(edge: .bottom))
                                .padding(.bottom)
                        }
                        .edgesIgnoringSafeArea(.bottom)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isViewLoaded = true
            }
        }
        .animation(.default, value: isShowingSendReceiptView)
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                .shadow(color: Color(.wooCommerceEmerald(.shade80)).opacity(Constants.shadowOpacity),
                        radius: Constants.shadowRadius, x: Constants.shadowSize.width, y: Constants.shadowSize.height)
                .foregroundColor(.posSuccessColor)
            Image(PointOfSaleAssets.successCheck.imageName)
                .renderingMode(.template)
                .foregroundColor(checkmarkColor)
                .frame(width: 52)
                .accessibilityHidden(true)
        }
    }

    private var checkmarkColor: Color {
        Color.primary
    }
}

private extension PointOfSaleTransactionSuccessView {
    enum Constants {
        static let imageName: String = "checkmark"
        static let imageSize: CGSize = .init(width: 165, height: 165)
        static let checkmarkSize: CGFloat = 56
        static let shadowOpacity: CGFloat = 0.16
        static let shadowRadius: CGFloat = 16
        static let shadowSize: CGSize = .init(width: 0, height: 8)
        static let headerSpacing: CGFloat = 56
        static let textSpacing: CGFloat = 16
        static let animationOffset: CGFloat = 100
    }
}

#Preview {
    return PointOfSaleTransactionSuccessView(
        viewModel: PointOfSaleTransactionSuccessViewModel(formattedOrderTotal: "$3.00")
    )
}
