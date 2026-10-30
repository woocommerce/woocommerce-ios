import Foundation
import enum Yosemite.PrinterError

/// Why a receipt failed to print, in the terms the merchant can act on.
enum POSPrintReceiptFailure: Hashable, Identifiable {
    case paperEmpty
    case coverOpen
    case printerOffline
    case generic

    var id: Self { self }

    init(error: Error) {
        switch error as? PrinterError {
        case .paperEmpty:
            self = .paperEmpty
        case .coverOpen:
            self = .coverOpen
        case .connectionLost, .printerNotConnected:
            self = .printerOffline
        default:
            self = .generic
        }
    }

    var title: String {
        switch self {
        case .paperEmpty:
            Localization.paperEmptyTitle
        case .coverOpen:
            Localization.coverOpenTitle
        case .printerOffline:
            Localization.printerOfflineTitle
        case .generic:
            Localization.genericTitle
        }
    }

    var message: String {
        switch self {
        case .paperEmpty:
            Localization.paperEmptyMessage
        case .coverOpen:
            Localization.coverOpenMessage
        case .printerOffline:
            Localization.printerOfflineMessage
        case .generic:
            Localization.genericMessage
        }
    }
}

private extension POSPrintReceiptFailure {
    enum Localization {
        static let paperEmptyTitle = NSLocalizedString(
            "pos.printReceiptFailure.paperEmpty.title",
            value: "Printer is out of paper",
            comment: "Title of the modal shown when a POS receipt can't print because the printer has no paper.")
        static let paperEmptyMessage = NSLocalizedString(
            "pos.printReceiptFailure.paperEmpty.message",
            value: "Load a new paper roll, then try again.",
            comment: "Message of the modal shown when a POS receipt can't print because the printer has no paper.")
        static let coverOpenTitle = NSLocalizedString(
            "pos.printReceiptFailure.coverOpen.title",
            value: "Printer cover is open",
            comment: "Title of the modal shown when a POS receipt can't print because the printer cover is open.")
        static let coverOpenMessage = NSLocalizedString(
            "pos.printReceiptFailure.coverOpen.message",
            value: "Close the printer cover, then try again.",
            comment: "Message of the modal shown when a POS receipt can't print because the printer cover is open.")
        static let printerOfflineTitle = NSLocalizedString(
            "pos.printReceiptFailure.printerOffline.title",
            value: "Can't reach your printer",
            comment: "Title of the modal shown when a POS receipt can't print because the printer connection was lost.")
        static let printerOfflineMessage = NSLocalizedString(
            "pos.printReceiptFailure.printerOffline.message",
            value: "Make sure your printer is on and nearby with Bluetooth turned on, then try again.",
            comment: "Message of the modal shown when a POS receipt can't print because the printer connection was lost.")
        static let genericTitle = NSLocalizedString(
            "pos.printReceiptFailure.generic.title",
            value: "Couldn't print the receipt",
            comment: "Title of the modal shown when a POS receipt fails to print for an unknown reason.")
        static let genericMessage = NSLocalizedString(
            "pos.printReceiptFailure.generic.message",
            value: "Something went wrong while printing. Please try again.",
            comment: "Message of the modal shown when a POS receipt fails to print for an unknown reason.")
    }
}
