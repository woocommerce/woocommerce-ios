import SwiftUI

struct PointOfSaleCardPresentPaymentAlert: View {
    private let alertType: PointOfSaleCardPresentPaymentAlertType

    init(alertType: PointOfSaleCardPresentPaymentAlertType) {
        self.alertType = alertType
    }

    var body: some View {
        alertContent
            .padding(PointOfSaleReaderConnectionModalLayout.contentPadding)
            .frame(width: frameWidth, height: frameHeight)
    }

    @ViewBuilder
    private var alertContent: some View {
        switch alertType {
        case .scanningForReaders(let alertViewModel):
            PointOfSaleCardPresentPaymentScanningForReadersView(viewModel: alertViewModel)
        case .scanningFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentScanningForReadersFailedView(viewModel: alertViewModel)
        case .bluetoothRequired(let alertViewModel):
            PointOfSaleCardPresentPaymentBluetoothRequiredAlertView(viewModel: alertViewModel)
        case .foundReader(let alertViewModel):
            PointOfSaleCardPresentPaymentFoundReaderView(viewModel: alertViewModel)
        case .foundMultipleReaders(let alertViewModel):
            PointOfSaleCardPresentPaymentFoundMultipleReadersView(viewModel: alertViewModel)
        case .requiredReaderUpdateInProgress(let alertViewModel):
            PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressView(viewModel: alertViewModel)
        case .optionalReaderUpdateInProgress(let alertViewModel):
            PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView(viewModel: alertViewModel)
        case .readerUpdateCompletion(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateCompletionView(viewModel: alertViewModel)
        case .updateFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedView(viewModel: alertViewModel)
        case .updateFailedNonRetryable(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(viewModel: alertViewModel)
        case .updateFailedLowBattery(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView(viewModel: alertViewModel)
        case .connectingToReader(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingToReaderView(viewModel: alertViewModel)
        case .connectingFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedView(viewModel: alertViewModel)
        case .connectingFailedNonRetryable(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView(viewModel: alertViewModel)
        case .connectingFailedChargeReader(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(viewModel: alertViewModel)
        case .connectingFailedUpdateAddress(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView(viewModel: alertViewModel)
        case .connectingFailedUpdatePostalCode(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView(viewModel: alertViewModel)
        case .connectionSuccess(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectionSuccessAlertView(viewModel: alertViewModel)
        }
    }

    @Environment(\.sizeCategory) private var sizeCategory

    private var frameWidth: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small:
            return 560
        case .medium, .large, .extraLarge:
            return 640
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 720
        case .accessibilityMedium,
                .accessibilityLarge,
                .accessibilityExtraLarge,
                .accessibilityExtraExtraLarge,
                .accessibilityExtraExtraExtraLarge:
            return windowBounds.width
        @unknown default:
            return 640
        }
    }

    private var frameHeight: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small:
            return 624
        case .medium, .large, .extraLarge:
            return 656
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 688
        case .accessibilityMedium,
                .accessibilityLarge,
                .accessibilityExtraLarge,
                .accessibilityExtraExtraLarge,
                .accessibilityExtraExtraExtraLarge:
            return windowBounds.height
        @unknown default:
            return 656
        }
    }

    private var windowBounds: CGRect {
        window?.bounds ?? UIScreen.main.bounds
    }

    private var window: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
}
