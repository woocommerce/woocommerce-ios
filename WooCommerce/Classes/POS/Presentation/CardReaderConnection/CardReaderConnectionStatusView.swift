import SwiftUI

enum CardReaderConnectionStatus {
    case connected
    case disconnecting
    case disconnected
}

struct CardReaderConnectionStatusView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @ObservedObject private var connectionViewModel: CardReaderConnectionViewModel
    @ScaledMetric private var scale: CGFloat = 1.0

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
                Menu {
                    Button {
                        connectionViewModel.disconnectReader()
                    } label: {
                        Text(Localization.disconnectCardReader)
                    }
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color(.wooCommerceEmerald(.shade40)))
                        Text(Localization.readerConnected)
                            .foregroundColor(connectedFontColor)
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                    .frame(maxHeight: .infinity)
                }
            case .disconnecting:
                HStack(spacing: Constants.buttonImageAndTextSpacing) {
                    ProgressView()
                        .progressViewStyle(POSProgressViewStyle(
                            size: Constants.disconnectingProgressIndicatorDimension * scale,
                            lineWidth: Constants.disconnectingProgressIndicatorLineWidth * scale
                        ))
                    Text(Localization.readerDisconnecting)
                        .foregroundColor(connectedFontColor)
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .frame(maxHeight: .infinity)
            case .disconnected:
                Button {
                    connectionViewModel.connectReader()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color(.wooCommerceAmber(.shade60)))
                        Text(Localization.readerDisconnected)
                            .foregroundColor(disconnectedFontColor)
                    }
                    .padding(.horizontal, Constants.horizontalPadding / 2)
                    .frame(maxHeight: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: Constants.overlayRadius)
                            .stroke(Constants.overlayColor, lineWidth: Constants.overlayLineWidth)
                    }
                    .padding(.horizontal, Constants.horizontalPadding / 2)
                    .padding(.vertical, Constants.verticalPadding)
                    .frame(maxHeight: .infinity)
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
        static let disconnectingProgressIndicatorDimension: CGFloat = 10
        static let disconnectingProgressIndicatorLineWidth: CGFloat = 2
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
            value: "Reader connected",
            comment: "The title of the floating button to indicate that reader is connected."
        )

        static let readerDisconnected = NSLocalizedString(
            "pointOfSale.floatingButtons.readerDisconnected.title",
            value: "Connect your reader",
            comment: "The title of the floating button to indicate that reader is disconnected and prompt connect after tapping."
        )

        static let readerDisconnecting = NSLocalizedString(
            "pointOfSale.floatingButtons.readerDisconnecting.title",
            value: "Disconnecting",
            comment: "The title of the floating button to indicate that reader is in the process " +
            " of disconnecting."
        )

        static let disconnectCardReader = NSLocalizedString(
            "pointOfSale.floatingButtons.disconnectCardReader.button.title",
            value: "Disconnect Reader",
            comment: "The title of the menu button to disconnect a connected card reader, as confirmation.")
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView(connectionViewModel: .init(cardPresentPayment: CardPresentPaymentPreviewService()))
    }
}

#endif
