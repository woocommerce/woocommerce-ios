import SwiftUI

struct CardReaderConnectionStatusView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @ObservedObject private var connectionViewModel: CardReaderConnectionViewModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.isEnabled) var isEnabled

    init(connectionViewModel: CardReaderConnectionViewModel) {
        self.connectionViewModel = connectionViewModel
    }

    @ViewBuilder
    private func circleIcon(with color: Color) -> some View {
        Image(systemName: "circle.fill")
            .resizable()
            .frame(width: Constants.imageDimension * min(scale, 1.5), height: Constants.imageDimension * min(scale, 1.5))
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
                progressIndicatingCardReaderStatus(title: Localization.readerDisconnecting)
            case .cancellingConnection:
                progressIndicatingCardReaderStatus(title: Localization.pleaseWait)
            case .disconnected:
                Button {
                    connectionViewModel.connectReader()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color(.wooCommerceAmber(.shade60)))
                        Text(Localization.readerDisconnected)
                            .foregroundColor(disconnectedFontColor)
                    }
                    .padding(.horizontal, Constants.overlayInnerHorizontalPadding)
                    .frame(maxHeight: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: Constants.overlayRadius)
                            .stroke(Constants.overlayColor, lineWidth: Constants.overlayLineWidth)
                    }
                    .padding(.horizontal, Constants.overlayOuterHorizontalPadding)
                    .padding(.vertical, Constants.overlayOuterVerticalPadding)
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .font(Constants.font, maximumContentSizeCategory: .accessibilityLarge)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

private extension CardReaderConnectionStatusView {
    @ViewBuilder
    func progressIndicatingCardReaderStatus(title: String) -> some View {
        HStack(spacing: Constants.buttonImageAndTextSpacing) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle(
                    size: Constants.progressIndicatorDimension * scale,
                    lineWidth: Constants.progressIndicatorLineWidth * scale
                ))
            Text(title)
                .foregroundColor(connectedFontColor)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(maxHeight: .infinity)
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
        static let progressIndicatorDimension: CGFloat = 10
        static let progressIndicatorLineWidth: CGFloat = 2
        static let font = POSFontStyle.posDetailEmphasized
        static let horizontalPadding: CGFloat = 24
        static let overlayRadius: CGFloat = 4
        static let overlayLineWidth: CGFloat = 2
        static let overlayColor: Color = Color.init(uiColor: .wooCommercePurple(.shade60))
        static let overlayInnerHorizontalPadding: CGFloat =  16 + Self.overlayLineWidth
        static let overlayOuterHorizontalPadding: CGFloat = 8 + Self.overlayLineWidth
        static let overlayOuterVerticalPadding: CGFloat = 8 + Self.overlayLineWidth
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
            comment: "The title of the menu button to disconnect a connected card reader, as confirmation."
        )

        static let pleaseWait = NSLocalizedString(
            "pointOfSale.floatingButtons.cancellingConnection.pleaseWait.title",
            value: "Please wait",
            comment: "The title of the floating button to indicate that the reader is not ready for another " +
            "connection, usually because a connection has just been cancelled" 
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
