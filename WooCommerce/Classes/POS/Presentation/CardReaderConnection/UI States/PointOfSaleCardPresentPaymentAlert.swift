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
            PointOfSaleCardPresentPaymentScanningForReadersView(viewModel: alertViewModel, animation: animation)
        case .scanningFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentScanningForReadersFailedView(viewModel: alertViewModel, animation: animation)
        case .bluetoothRequired(let alertViewModel):
            PointOfSaleCardPresentPaymentBluetoothRequiredAlertView(viewModel: alertViewModel, animation: animation)
        case .foundReader(let alertViewModel):
            PointOfSaleCardPresentPaymentFoundReaderView(viewModel: alertViewModel, animation: animation)
        case .foundMultipleReaders(let alertViewModel):
            PointOfSaleCardPresentPaymentFoundMultipleReadersView(viewModel: alertViewModel, animation: animation)
        case .requiredReaderUpdateInProgress(let alertViewModel):
            PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressView(viewModel: alertViewModel, animation: animation)
        case .optionalReaderUpdateInProgress(let alertViewModel):
            PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView(viewModel: alertViewModel, animation: animation)
        case .readerUpdateCompletion(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateCompletionView(viewModel: alertViewModel, animation: animation)
        case .updateFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedView(viewModel: alertViewModel, animation: animation)
        case .updateFailedNonRetryable(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(viewModel: alertViewModel, animation: animation)
        case .updateFailedLowBattery(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView(viewModel: alertViewModel, animation: animation)
        case .connectingToReader(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingToReaderView(viewModel: alertViewModel, animation: animation)
        case .connectingFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedView(viewModel: alertViewModel, animation: animation)
        case .connectingFailedNonRetryable(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView(viewModel: alertViewModel, animation: animation)
        case .connectingFailedChargeReader(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(viewModel: alertViewModel, animation: animation)
        case .connectingFailedUpdateAddress(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView(viewModel: alertViewModel, animation: animation)
        case .connectingFailedUpdatePostalCode(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView(viewModel: alertViewModel, animation: animation)
        case .connectionSuccess(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectionSuccessAlertView(viewModel: alertViewModel, animation: animation)
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

    // MARK: - Animations

    /// Used together with .matchedGeometryEffect
    /// This makes SwiftUI treat different messages as a single view in the context of animation.
    /// Allows to smoothly transition from one view to another while also transitioning to full-screen
    @Namespace private var namespace
    private var animation: POSCardPresentPaymentAlertAnimation { .init(namespace: namespace) }
}

struct POSCardPresentPaymentAlertAnimation {
    let namespace: Namespace.ID
    let iconTransitionId: String = "pos_card_present_payment_payment_alert_icon_matched_geometry_id"
    let titleTransitionId: String = "pos_card_present_payment_payment_alert_title_matched_geometry_id"
    let contentTransitionId: String = "pos_card_present_payment_payment_alert_content_matched_geometry_id"
    let buttonsTransitionId: String = "pos_card_present_payment_payment_alert_buttons_matched_geometry_id"
}
