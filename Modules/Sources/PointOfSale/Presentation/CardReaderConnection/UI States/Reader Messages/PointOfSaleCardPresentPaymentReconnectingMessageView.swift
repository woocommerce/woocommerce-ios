import SwiftUI

struct PointOfSaleCardPresentPaymentReconnectingMessageView: View {
    @Environment(\.posMetrics) private var metrics
    private let viewModel = PointOfSaleCardPresentPaymentReconnectingMessageViewModel()
    private let cancelReconnection: () -> Void
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var isCancelling = false

    init(cancelReconnection: @escaping () -> Void) {
        self.cancelReconnection = cancelReconnection
    }

    var body: some View {
        VStack(alignment: .center, spacing: metrics.spacing.none) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: Constants.spinnerDimension, height: Constants.spinnerDimension)

            Spacer()
                .frame(height: dynamicSpacing(metrics.spacing.large))

            Text(viewModel.title)
                .font(.posHeadingBold)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, metrics.padding.xxLarge)

            Spacer()
                .frame(height: dynamicSpacing(metrics.spacing.xxLarge))

            Button {
                isCancelling = true
                cancelReconnection()
            } label: {
                Text(viewModel.cancelReconnectionButtonTitle)
                    .minimumScaleFactor(1)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isCancelling))
            .posStatusButtonsWidth()
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .onAppear {
            isCancelling = false
        }
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
