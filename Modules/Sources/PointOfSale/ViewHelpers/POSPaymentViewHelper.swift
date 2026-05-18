import Foundation
import SwiftUI

/// Shared view helper methods used by both cart (TotalsView) and bookings (POSPaymentContentView) payment flows.
struct POSPaymentViewHelper {
    func paymentBackgroundColor(for paymentState: PointOfSalePaymentState) -> Color {
        switch paymentState.activePaymentMethod {
        case .cash:
            switch paymentState.cash {
            case .collectingCash, .paymentSuccess:
                return .posSurfaceBright
            default:
                return .clear
            }
        case .scanToPay:
            switch paymentState.scanToPay {
            case .showingQRCode, .paymentSuccess:
                return .posSurfaceBright
            case .idle:
                return .clear
            }
        case .markAsPaid:
            switch paymentState.markAsPaid {
            case .paymentSuccess:
                return .posSurfaceBright
            case .idle, .confirming, .processing:
                return .clear
            }
        case .card:
            switch paymentState.card {
            case .processingPayment:
                return .posPrimary
            case .cardPaymentSuccessful:
                return .posSurfaceBright
            default:
                return .clear
            }
        }
    }

    func shouldShowCashPaymentButton(paymentState: PointOfSalePaymentState,
                                     cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                     isZeroTotal: Bool = false) -> Bool {
        if isZeroTotal, case .card = paymentState.activePaymentMethod {
            return true
        }
        switch paymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return false
        case .card:
            if case .disconnected = cardReaderConnectionStatus,
               case .idle = paymentState.card {
                return true
            }
            return paymentState.allowsCashPayment && paymentState.card != .idle
        }
    }

    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return false
        case .card:
            switch paymentState.card {
            case .idle,
                    .acceptingCard,
                    .cardInserted,
                    .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .preparingReader:
                return true
            case .processingPayment,
                    .paymentError,
                    .cardPaymentSuccessful:
                return false
            }
        }
    }

    func shouldShowDisconnectedMessage(readerConnectionStatus: CardPresentPaymentReaderConnectionStatus,
                                       paymentState: PointOfSalePaymentState) -> Bool {
        guard readerConnectionStatus == .disconnected else {
            return false
        }

        switch paymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return false
        case .card:
            switch paymentState.card {
            case .idle,
                    .acceptingCard,
                    .preparingReader:
                return true
            case .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .processingPayment,
                    .cardInserted,
                    .paymentError,
                    .cardPaymentSuccessful:
                return false
            }
        }
    }

    func shouldApplyPadding(paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return false
        case .card:
            switch paymentState.card {
            case .cardPaymentSuccessful, .paymentError:
                return false
            case .idle,
                    .acceptingCard,
                    .cardInserted,
                    .validatingOrder,
                    .validatingOrderError,
                    .paymentIntentCreationError,
                    .preparingReader,
                    .processingPayment:
                return true
            }
        }
    }
}
