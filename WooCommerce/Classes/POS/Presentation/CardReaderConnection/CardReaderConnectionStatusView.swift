import SwiftUI

enum CardReaderConnectionStatus {
    case connected
    case disconnected
}

struct CardReaderConnectionStatusView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @ObservedObject private var connectionViewModel: CardReaderConnectionViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme

    init(connectionViewModel: CardReaderConnectionViewModel) {
        self.connectionViewModel = connectionViewModel
    }

    @ViewBuilder
    private func circleIcon(with color: Color) -> some View {
        Image(systemName: "circle.fill")
            .resizable()
            .frame(width: Constants.imageDimension * scale, height: Constants.imageDimension * scale)
            .foregroundColor(color)
            .accessibilityHidden(true)
    }

    var body: some View {
        Group {
            switch connectionViewModel.connectionStatus {
            case .connected:
                HStack(spacing: Constants.buttonImageAndTextSpacing) {
                    circleIcon(with: Color(.wooCommerceEmerald(.shade40)))
                    Text(Localization.readerConnected)
                        .foregroundColor(connectedFontColor)
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
            case .disconnected:
                Button {
                    connectionViewModel.connectReader()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color(.wooCommerceAmber(.shade60)))
                        Text(Localization.readerDisconnected)
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
        .font(Constants.font, maximumContentSizeCategory: .accessibilityLarge)
    }
}

private extension CardReaderConnectionStatusView {
    var connectedFontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posPrimaryText
        case .secondary:
            POSFloatingControlView.secondaryFontColor
        }
    }

    var disconnectedFontColor: Color {
        switch backgroundAppearance {
        case .primary:
            Color(.wooCommercePurple(.shade60))
        case .secondary:
            POSFloatingControlView.secondaryFontColor
        }
    }
}

private extension CardReaderConnectionStatusView {
    enum Constants {
        static let buttonImageAndTextSpacing: CGFloat = 12
        static let imageDimension: CGFloat = 12
        static let font = POSFontStyle.posDetailEmphasized
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let overlayRadius: CGFloat = 4
        static let overlayLineWidth: CGFloat = 2
        static let overlayColor: Color = Color.init(uiColor: .wooCommercePurple(.shade60))
    }
}

private extension CardReaderConnectionStatusView {
    enum Localization {
        static let readerConnected = NSLocalizedString(
            "pointOfSale.floatingButtons.readerConnected.title",
            value: "Reader Connected",
            comment: "The title of the floating button to indicate that reader is connected."
        )

        static let readerDisconnected = NSLocalizedString(
            "pointOfSale.floatingButtons.readerDisconnected.title",
            value: "Connect your reader",
            comment: "The title of the floating button to indicate that reader is disconnected and prompt connect after tapping."
        )
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()))
    }
}

#endif
