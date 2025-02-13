import SwiftUI

@available(iOS 17.0, *)
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
            case .disconnecting:
                progressIndicatingCardReaderStatus(title: Localization.readerDisconnecting)
            case .cancellingConnection:
                progressIndicatingCardReaderStatus(title: Localization.pleaseWait)
            case .disconnected:
                HStack(spacing: Constants.horizontalPadding) {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        circleIcon(with: Color.posAlert)
                        Text(Localization.readerDisconnected)
                            .foregroundColor(disconnectedFontColor)
                    }

                    Button {
                        posModel.connectCardReader()
                    } label: {
                        Text(Localization.connectReader)
                    }
                    .buttonStyle(POSFilledButtonStyle(size: .extraSmall))
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .frame(maxHeight: .infinity)
            }
        }
        .font(Constants.font, maximumContentSizeCategory: .accessibilityLarge)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
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
            .posOnSurface
        case .secondary:
            POSFloatingControlView.secondaryFontColor
        }
    }
}

@available(iOS 17.0, *)
private extension CardReaderConnectionStatusView {
    enum Constants {
        static let buttonImageAndTextSpacing: CGFloat = 16
        static let imageDimension: CGFloat = 12
        static let progressIndicatorDimension: CGFloat = 10
        static let progressIndicatorLineWidth: CGFloat = 2
        static let font = POSFontStyle.posBodyMediumRegular()
        static let horizontalPadding: CGFloat = 24
    }
}

@available(iOS 17.0, *)
private extension CardReaderConnectionStatusView {
    enum Localization {
        static let readerConnected = NSLocalizedString(
            "pointOfSale.floatingButtons.readerConnected.title",
            value: "Reader connected",
            comment: "The title of the floating button to indicate that reader is connected."
        )

        static let readerDisconnected = NSLocalizedString(
            "pointOfSale.floatingButtons.readerNotConnected.title",
            value: "Reader not connected",
            comment: "The title of the floating button to indicate that reader is disconnected and prompt connect after tapping."
        )

        static let connectReader = NSLocalizedString(
            "pointOfSale.floatingButtons.connectCardReader.button.title",
            value: "Connect",
            comment: "The title of the menu button to connect a card reader."
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

@available(iOS 17.0, *)
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController()
    )
    VStack {
        CardReaderConnectionStatusView()
            .environment(posModel)
    }
}

#endif
