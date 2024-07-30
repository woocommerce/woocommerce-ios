import SwiftUI

enum CardReaderConnectionStatus {
    case connected
    case disconnected
}

struct CardReaderConnectionStatusView: View {
    @ObservedObject private var connectionViewModel: CardReaderConnectionViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ScaledMetric private var scale: CGFloat = 1.0

    init(connectionViewModel: CardReaderConnectionViewModel, totalsViewModel: TotalsViewModel) {
        self.connectionViewModel = connectionViewModel
        self.totalsViewModel = totalsViewModel
    }

    @ViewBuilder
    private func circleIcon(with color: Color) -> some View {
        Image(systemName: "circle.fill")
            .resizable()
            .frame(width: Constants.imageDimension * scale, height: Constants.imageDimension * scale)
            .foregroundColor(color)
    }

    var body: some View {
        Group {
            switch connectionViewModel.connectionStatus {
            case .connected:
                HStack(spacing: Constants.buttonImageAndTextSpacing) {
                    circleIcon(with: Color.wooEmeraldShade40)
                    Text("Reader Connected")
                        .foregroundColor(connectedFontColor)
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
            case .disconnected:
                Button {
                    connectionViewModel.connectReader()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color.wooAmberShade60)
                        Text("Connect your reader")
                            .foregroundColor(disconnectedFontColor)
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
                .overlay {
                    RoundedRectangle(cornerRadius: Constants.overlayRadius)
                        .stroke(Constants.overlayColor, lineWidth: Constants.overlayLineWidth)
                }
            }
        }
        .font(Constants.font)
    }

    private var connectedFontColor: Color {
        if totalsViewModel.paymentState == .processingPayment {
            return .posSecondaryTextDark
        } else {
            return .primaryText
        }
    }

    private var disconnectedFontColor: Color {
        if totalsViewModel.paymentState == .processingPayment {
            return .posSecondaryTextDark
        } else {
            return Color(.wooCommercePurple(.shade60))
        }
    }
}

private extension CardReaderConnectionStatusView {
    enum Constants {
        static let buttonImageAndTextSpacing: CGFloat = 12
        static let imageDimension: CGFloat = 12
        static let font = Font.system(size: 16.0, weight: .semibold)
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let overlayRadius: CGFloat = 4
        static let overlayLineWidth: CGFloat = 2
        static let overlayColor: Color = Color.init(uiColor: .wooCommercePurple(.shade60))
    }
}

#if DEBUG

#Preview {
    VStack {
        let totalsViewModel = TotalsViewModel(orderService: POSOrderPreviewService(),
                                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                              currencyFormatter: .init(currencySettings: .init()),
                                              paymentState: .acceptingCard,
                                              isSyncingOrder: false)
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()), totalsViewModel: totalsViewModel)
    }
}

#endif
