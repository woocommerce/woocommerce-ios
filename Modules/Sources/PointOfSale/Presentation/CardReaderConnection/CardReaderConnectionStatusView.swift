import SwiftUI

struct CardReaderConnectionStatusView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.isEnabled) var isEnabled

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
            switch posModel.cardReaderConnectionStatus {
            case .connected:
                Menu {
                    Button {
                        posModel.disconnectCardReader()
                    } label: {
                        Text(Localization.disconnectCardReader)
                    }
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color.posSuccess)
                        Text(Localization.readerConnected)
                            .foregroundColor(connectedFontColor)
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                    .frame(maxHeight: .infinity)
                }
                .accessibilityIdentifier("pos-reader-connected")
            case .disconnecting:
                progressIndicatingCardReaderStatus(title: Localization.readerDisconnecting)
            case .cancellingConnection:
                progressIndicatingCardReaderStatus(title: Localization.pleaseWait)
            case .disconnected:
                Button {
                    posModel.connectCardReader()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color.posAlert)
                        Text(Localization.readerDisconnected)
                            .foregroundColor(disconnectedFontColor)
                    }
                    .padding(.horizontal, Constants.disconnectedBorderAndContentSpacing)
                    .frame(maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.disconnectedBorderCornerRadius)
                            .stroke(disconnectedBorderColor, lineWidth: Constants.disconnectedBorderWidth)
                    )
                    .padding(Constants.disconnectedBorderInset)
                }
                .accessibilityIdentifier("pos-connect-reader-button")
            case .reconnecting:
                Menu {
                    Button {
                        posModel.cancelReconnection()
                    } label: {
                        Text(Localization.cancelReconnection)
                    }
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        ProgressView()
                            .progressViewStyle(POSProgressViewStyle(
                                size: Constants.progressIndicatorDimension * scale,
                                lineWidth: Constants.progressIndicatorLineWidth * scale
                            ))
                        Text(Localization.readerReconnecting)
                            .foregroundColor(connectedFontColor)
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                    .frame(maxHeight: .infinity)
                }
                .accessibilityIdentifier("pos-reader-reconnecting")
            }
        }
        .font(Constants.font)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
            .posOnSurface
        case .secondary:
            POSFloatingControlView.secondaryFontColor
        }
    }

    var disconnectedFontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posOnSurface
        case .secondary:
            POSFloatingControlView.secondaryFontColor
        }
    }

    var disconnectedBorderColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posPrimary
        case .secondary:
            POSFloatingControlView.secondaryFontColor
        }
    }
}

private extension CardReaderConnectionStatusView {
    enum Constants {
        static let buttonImageAndTextSpacing: CGFloat = POSSpacing.medium
        static let imageDimension: CGFloat = 14
        static let progressIndicatorDimension: CGFloat = 10
        static let progressIndicatorLineWidth: CGFloat = 2
        static let font = POSFontStyle.posBodyMediumRegular()
        static let horizontalPadding: CGFloat = POSPadding.large
        static let disconnectedBorderAndContentSpacing: CGFloat = POSSpacing.medium
        static let disconnectedBorderCornerRadius: CGFloat = POSCornerRadiusStyle.small.value
        static let disconnectedBorderWidth: CGFloat = 2
        static let disconnectedBorderInset: CGFloat = POSSpacing.small
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
            "pointOfSale.floatingButtons.disconnectCardReader.button.title.2",
            value: "Disconnect reader",
            comment: "The title of the menu button to disconnect a connected card reader, as confirmation."
        )

        static let pleaseWait = NSLocalizedString(
            "pointOfSale.floatingButtons.cancellingConnection.pleaseWait.title",
            value: "Please wait",
            comment: "The title of the floating button to indicate that the reader is not ready for another " +
            "connection, usually because a connection has just been cancelled"
        )

        static let readerReconnecting = NSLocalizedString(
            "pointOfSale.floatingButtons.readerReconnecting.title",
            value: "Reconnecting…",
            comment: "The title of the floating button to indicate that the reader is attempting to reconnect."
        )

        static let cancelReconnection = NSLocalizedString(
            "pointOfSale.floatingButtons.cancelReconnection.button.title",
            value: "Cancel reconnection",
            comment: "The title of the menu button to cancel an ongoing card reader reconnection attempt."
        )
    }
}

#if DEBUG

#Preview {
    VStack {
        CardReaderConnectionStatusView()
            .background(Color.posSurfaceContainerLow)
            .frame(height: 80)
            .environment(POSPreviewHelpers.makePreviewAggregateModel())
    }
}

#endif
