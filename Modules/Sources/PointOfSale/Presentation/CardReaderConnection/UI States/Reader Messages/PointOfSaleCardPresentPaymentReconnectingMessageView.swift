import SwiftUI

struct PointOfSaleCardPresentPaymentReconnectingMessageView: View {
    private let viewModel = PointOfSaleCardPresentPaymentReconnectingMessageViewModel()
    private let cancelReconnection: () -> Void
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var width: CGFloat = 0

    init(cancelReconnection: @escaping () -> Void) {
        self.cancelReconnection = cancelReconnection
    }

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.none) {
            Spacer().frame(minHeight: 0)
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: Constants.spinnerDimension, height: Constants.spinnerDimension)

            Spacer()
                .frame(height: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing))

            Text(viewModel.title)
                .font(.posHeadingBold)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, PointOfSaleCardPresentPaymentLayout.horizontalPadding)

            Spacer()
                .frame(height: dynamicSpacing(PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing))

            Button {
                cancelReconnection()
            } label: {
                Text(viewModel.cancelReconnectionButtonTitle)
                    .minimumScaleFactor(1)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(width: width * 0.5)
            Spacer().frame(minHeight: 0)
        }
        .frame(maxWidth: .infinity)
        .measureWidth({ containerWidth in
            width = containerWidth
        })
        .multilineTextAlignment(.center)
    }

    private func dynamicSpacing(_ spacing: CGFloat) -> CGFloat {
        guard scale > 1 else {
            return spacing
        }

        return spacing * (1 / scale)
    }
}

private extension PointOfSaleCardPresentPaymentReconnectingMessageView {
    enum Constants {
        static let spinnerDimension: CGFloat = 160
    }
}

#if DEBUG
#Preview {
    PointOfSaleCardPresentPaymentReconnectingMessageView(cancelReconnection: {})
}
#endif
